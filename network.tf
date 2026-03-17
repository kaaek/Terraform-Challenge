# ─── Availability Zones ───
data "aws_availability_zones" "available" {
    state = "available"
}

# ─── Public Subnet 1 ───
resource "aws_subnet" "public_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidr_az1
    availability_zone = data.aws_availability_zones.available.names[0]
    map_public_ip_on_launch = true
    tags = { Name = "Lab-Public-Subnet-1" }
}

# ─── Public Subnet 2 (needed for ALB - must be in different AZ) ───
resource "aws_subnet" "public_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidr_az2
    availability_zone = data.aws_availability_zones.available.names[1]
    map_public_ip_on_launch = true
    tags = { Name = "Lab-Public-Subnet-2" }
}

# ─── Private Subnet 1 ───
resource "aws_subnet" "private_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidr_az1
    availability_zone = data.aws_availability_zones.available.names[0]
    tags = { Name = "Lab-Private-Subnet-1" }
}

# ─── Private Subnet 2 ───
resource "aws_subnet" "private_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidr_az2
    availability_zone = data.aws_availability_zones.available.names[1]
    tags = { Name = "Lab-Private-Subnet-2" }
}

# ─── Internet Gateway ───
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
    tags = { Name = "Lab-IGW" }
}

# ─── Elastic IPs for NAT Gateways ───
resource "aws_eip" "nat_1" {
    domain = "vpc"
    tags = { Name = "Lab-NAT-EIP-AZ1" }
}

resource "aws_eip" "nat_2" {
    domain = "vpc"
    tags = { Name = "Lab-NAT-EIP-AZ2" }
}

# ─── NAT Gateway in AZ1 (public subnet 1) ───
resource "aws_nat_gateway" "az1" {
    allocation_id = aws_eip.nat_1.id
    subnet_id = aws_subnet.public_1.id
    tags = { Name = "Lab-NAT-GW-AZ1" }
    depends_on = [aws_internet_gateway.main]
}

# ─── NAT Gateway in AZ2 (public subnet 2) ───
resource "aws_nat_gateway" "az2" {
    allocation_id = aws_eip.nat_2.id
    subnet_id = aws_subnet.public_2.id
    tags = { Name = "Lab-NAT-GW-AZ2" }
    depends_on = [aws_internet_gateway.main]
}

# ─── Public Route Table ───
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = { Name = "Lab-Public-RT" }
}

resource "aws_route_table_association" "public_1" {
    subnet_id = aws_subnet.public_1.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
    subnet_id = aws_subnet.public_2.id
    route_table_id = aws_route_table.public.id
}

# ─── Private Route Table AZ1 ───
resource "aws_route_table" "private_az1" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.az1.id
    }

    tags = { Name = "Lab-Private-RT-AZ1" }
}

resource "aws_route_table" "private_az2" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.az2.id
    }

    tags = { Name = "Lab-Private-RT-AZ2" }
}

resource "aws_route_table_association" "private_1" {
    subnet_id = aws_subnet.private_1.id
    route_table_id = aws_route_table.private_az1.id
}

resource "aws_route_table_association" "private_2" {
    subnet_id = aws_subnet.private_2.id
    route_table_id = aws_route_table.private_az2.id
}