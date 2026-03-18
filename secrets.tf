# 1 — The role itself (trust policy: who can assume it)
resource "aws_iam_role" "ec2_ssm_role" {
  name = "lab007-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# 2 — Attach AWS managed policy that allows SSM reads
resource "aws_iam_role_policy_attachment" "ssm_read" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# 3 — Instance profile (wraps the role so EC2 can use it)
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "lab007-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# 4 — Store secret in SSM Parameter Store
resource "aws_ssm_parameter" "db_password" {
  name  = "/lab/db_password"
  type  = "SecureString"
  value = var.db_password

  tags = {
    Name = "Lab-DB-Password"
  }
}