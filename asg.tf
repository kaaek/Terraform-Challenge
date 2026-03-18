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

    user_data = base64encode(replace(file("${path.module}/userdata/web.sh"), "BACKEND_IP:3000", "${aws_lb.backend.dns_name}:3000"))

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

        user_data = filebase64("${path.module}/userdata/backend.sh")

    tag_specifications {
        resource_type = "instance"
        tags = { Name = "Backend-ASG-Instance" }
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