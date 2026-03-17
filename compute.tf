# ─── Latest Amazon Linux 2023 AMI ───
data "aws_ami" "amazon_linux" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["al2023-ami-*-x86_64"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

# ─── Bastion Host ───
resource "aws_instance" "bastion" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_1.id
    vpc_security_group_ids = [aws_security_group.bastion.id]
    key_name = var.key_name
    tags = { Name = "Bastion-Host" }
}

# ─── Web Launch Template ───
resource "aws_launch_template" "web" {
    name_prefix = "lab-web-lt-"
    image_id = data.aws_ami.amazon_linux.id
    instance_type = "t2.micro"
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.web.id]

    iam_instance_profile {
        name = aws_iam_instance_profile.ec2_ssm_profile.name
    }

    user_data = base64encode(<<-EOF
        #!/bin/bash
        dnf update -y
        dnf install -y nginx

        cat > /etc/nginx/conf.d/default.conf <<NGINX
        server {
            listen 80;

            location / {
                proxy_pass http://${aws_lb.backend.dns_name}:3000;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            }
        }
        NGINX

        nginx -t
        systemctl enable nginx
        systemctl restart nginx
    EOF
    )

    tag_specifications {
        resource_type = "instance"
        tags = { Name = "Web-ASG-Instance" }
    }
}

# ─── Backend Launch Template ───
resource "aws_launch_template" "backend" {
    name_prefix = "lab-backend-lt-"
    image_id = data.aws_ami.amazon_linux.id
    instance_type = "t2.micro"
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.backend.id]

    iam_instance_profile {
        name = aws_iam_instance_profile.ec2_ssm_profile.name
    }

    user_data = base64encode(<<-EOF
        #!/bin/bash
        dnf update -y
        dnf install -y nodejs
        cat > /home/ec2-user/server.js <<'JS'
        const http = require('http');
        const server = http.createServer((req, res) => {
          res.writeHead(200, {'Content-Type': 'application/json'});
          res.end(JSON.stringify({ status: 'ok', tier: 'backend' }));
        });
        server.listen(3000, '0.0.0.0');
        JS
        nohup node /home/ec2-user/server.js > /var/log/backend.log 2>&1 &
    EOF
    )

    tag_specifications {
        resource_type = "instance"
        tags = { Name = "Backend-ASG-Instance" }
    }
}

# ─── External ALB for Web Tier ───
resource "aws_lb" "web" {
    name = "lab-web-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb.id]
    subnets = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    tags = { Name = "Lab-Web-ALB" }
}

resource "aws_lb_target_group" "web" {
    name = "lab-web-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.main.id
    target_type = "instance"

    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
    }
}

resource "aws_lb_listener" "web_http" {
    load_balancer_arn = aws_lb.web.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.web.arn
    }
}

# ─── Internal ALB for Backend Tier ───
resource "aws_lb" "backend" {
    name = "lab-backend-alb"
    internal = true
    load_balancer_type = "application"
    security_groups = [aws_security_group.backend_alb.id]
    subnets = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    tags = { Name = "Lab-Backend-ALB" }
}

resource "aws_lb_target_group" "backend" {
    name = "lab-backend-tg"
    port = 3000
    protocol = "HTTP"
    vpc_id = aws_vpc.main.id
    target_type = "instance"

    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
    }
}

resource "aws_lb_listener" "backend_http" {
    load_balancer_arn = aws_lb.backend.arn
    port = 3000
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.backend.arn
    }
}

# ─── Web Auto Scaling Group ───
resource "aws_autoscaling_group" "web" {
    name = "lab-web-asg"
    min_size = 2
    max_size = 4
    desired_capacity = 2
    vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    target_group_arns = [aws_lb_target_group.web.arn]
    health_check_type = "ELB"

    launch_template {
        id = aws_launch_template.web.id
        version = "$Latest"
    }

    tag {
        key = "Name"
        value = "Web-ASG"
        propagate_at_launch = true
    }
}

# ─── Backend Auto Scaling Group ───
resource "aws_autoscaling_group" "backend" {
    name = "lab-backend-asg"
    min_size = 2
    max_size = 4
    desired_capacity = 2
    vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    target_group_arns = [aws_lb_target_group.backend.arn]
    health_check_type = "ELB"

    launch_template {
        id = aws_launch_template.backend.id
        version = "$Latest"
    }

    tag {
        key = "Name"
        value = "Backend-ASG"
        propagate_at_launch = true
    }
}