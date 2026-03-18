# Terraform Challenge

Production-style two-tier AWS infrastructure provisioned with Terraform.

The stack deploys:
- A public web tier (Nginx) behind an internet-facing Application Load Balancer.
- A private backend tier (Node.js/Express API) behind an internal Application Load Balancer.
- A VPC with two public and two private subnets across two Availability Zones.
- One NAT Gateway per AZ for private subnet egress.
- Security groups enforcing tier-to-tier access controls.
- Auto Scaling Groups and Launch Templates for both tiers.
- A bastion host for SSH administration.
- A secure parameter in AWS SSM Parameter Store.

## Architecture

Request flow:
1. Client sends HTTP request to external web ALB.
2. Web ALB forwards traffic to Nginx instances in public subnets.
3. Nginx serves UI and reverse-proxies `/api/*` to internal backend ALB.
4. Internal backend ALB forwards requests to Express API instances in private subnets.

Network and placement:
- Public subnets: web tier, external ALB, bastion, NAT gateways.
- Private subnets: backend ALB and backend EC2 instances.
- Route tables:
  - Public route table: `0.0.0.0/0` -> Internet Gateway.
  - Private route tables (per AZ): `0.0.0.0/0` -> NAT Gateway in same AZ.

High-level diagram:

```text
Internet
	|
[External Web ALB :80]
	|
[Web ASG (Nginx) in Public Subnets]
	|
  /api/* reverse proxy
	|
[Internal Backend ALB :3000]
	|
[Backend ASG (Node.js API) in Private Subnets]
```

## Repository Structure

- `main.tf`: provider + VPC resource.
- `variables.tf`: input variables.
- `network.tf`: subnets, IGW, NAT gateways, route tables.
- `security.tf`: security groups for bastion, ALBs, web, backend.
- `alb.tf`: external and internal ALBs, listeners, target groups.
- `compute.tf`: AMI data source and bastion host.
- `asg.tf`: launch templates + ASGs for web and backend tiers.
- `secrets.tf`: IAM role/profile for EC2 + SSM SecureString parameter.
- `outputs.tf`: ALB DNS names, bastion IP, SSM parameter name.
- `userdata/web.sh`: Nginx + static frontend + reverse proxy config.
- `userdata/backend.sh`: Express API bootstrap script.
- `terraform.tfvars`: environment values (region, key pair, SSH source CIDR).

## Prerequisites

- Terraform `>= 1.x`.
- AWS account with permissions for: VPC, EC2, IAM, ELBv2, Auto Scaling, SSM, EIP, NAT.
- AWS CLI configured (`aws configure`) or equivalent credentials in environment.
- An existing EC2 key pair in target region (`key_name`).

## Input Variables

Defined in `variables.tf`:

- `aws_region` (default: `eu-central-1`)
- `vpc_cidr` (default: `172.16.0.0/16`)
- `public_subnet_cidr_az1` (default: `172.16.1.0/24`)
- `public_subnet_cidr_az2` (default: `172.16.2.0/24`)
- `private_subnet_cidr_az1` (default: `172.16.10.0/24`)
- `private_subnet_cidr_az2` (default: `172.16.11.0/24`)
- `key_name` (required)
- `my_ip` (required, CIDR format, used for bastion SSH ingress)
- `app_secret` (required, sensitive)

Example `terraform.tfvars`:

```hcl
aws_region = "eu-central-1"
key_name   = "your-keypair-name"
my_ip      = "203.0.113.10/32"
app_secret = "replace-with-secret-value"
```

## Deployment

From repository root:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Optional non-interactive apply:

```bash
terraform apply -auto-approve
```

## Outputs

After apply, Terraform returns:

- `web_alb_dns_name`: public endpoint for the application.
- `backend_alb_dns_name`: internal backend ALB DNS (VPC-only reachable).
- `bastion_public_ip`: public IP of bastion instance.
- `app_secret_parameter_name`: SSM parameter path (default `/lab/app_secret`).

## Validation Steps

1. Open `http://<web_alb_dns_name>`.
2. Verify frontend page loads.
3. Verify backend health and data cards render successfully.
4. Confirm backend is not internet-exposed:
	- backend ALB is internal-only.
	- backend security group only allows port `3000` from backend ALB SG.

## Security Notes

- `my_ip` should be your public IP in `/32` form for bastion SSH.
- Do not use `0.0.0.0/0` for SSH in real environments.
- `app_secret` is stored as `SecureString` in SSM Parameter Store.
- EC2 instances receive `AmazonSSMReadOnlyAccess` via IAM role.

## Current Behavior and Limits

- The web bootstrap script injects backend internal ALB DNS into Nginx reverse proxy configuration.
- Backend API serves `/api/health` and `/api/data` and includes EC2 metadata in responses.
- The SSM secret is created and permissioned, but application code does not currently read it.

## Troubleshooting

- ALB target unhealthy:
  - Check EC2 user-data logs (`/var/log/cloud-init-output.log`).
  - Verify service health endpoints:
	 - web target group expects `GET /` -> `200`.
	 - backend target group expects `GET /api/health` -> `200`.
- No backend data in UI:
  - Confirm Nginx reverse proxy config contains backend ALB DNS.
  - Validate backend instances are healthy in backend target group.
- Terraform apply fails on IAM name conflicts:
  - Role/profile names are fixed; rename resources or import existing ones.

## Teardown

Destroy all resources:

```bash
terraform destroy
```

## License

See `LICENSE`.
