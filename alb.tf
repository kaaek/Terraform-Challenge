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
        path = "/api/health"
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