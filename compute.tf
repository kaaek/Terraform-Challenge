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