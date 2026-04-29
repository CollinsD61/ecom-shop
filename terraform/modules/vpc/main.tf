resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.env}-vpc"
    Environment = var.env
  }
}

# interet gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${var.env}-igw"
    Environment = var.env
  }
}

# public subnet
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                            = "${var.env}-public-subnet-${count.index + 1}"
    Environment                                     = var.env
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.env}-ecom-cluster" = "shared"
  }
}

# private subnet
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                            = "${var.env}-private-subnet-${count.index + 1}"
    Environment                                     = var.env
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.env}-ecom-cluster" = "shared"
  }
}

# option nat for each environment
locals {
  nat_gateway_count = var.env == "dev" ? 1 : length(var.availability_zones)
}

resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = {
    Name        = "${var.env}-nat-eip-${count.index + 1}"
    Environment = var.env
  }
}

resource "aws_nat_gateway" "this" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id

  subnet_id = aws_subnet.public[count.index].id

  tags = { Name = "${var.env}-nat-gw-${count.index + 1}" }

  depends_on = [aws_internet_gateway.this]
}

#route table for public subnet

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name        = "${var.env}-public-rt"
    Environment = var.env
  }
}

# attach public subnet to route table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# route table for private subnet
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${var.env}-private-rt-${count.index + 1}"
    Environment = var.env
  }
}

#route to nat gateway (logic min to resolve Dev vs Prod)
resource "aws_route" "private_to_nat" {
  count                  = length(var.private_subnet_cidrs)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"

  # Logic: 
  # - Ở Dev: local.nat_gateway_count = 1 -> Cả 2 Route Table đều trỏ về NAT[0]
  # - Ở Prod: local.nat_gateway_count = 2 -> RT[0] trỏ về NAT[0], RT[1] trỏ về NAT[1]
  nat_gateway_id = aws_nat_gateway.this[min(count.index, local.nat_gateway_count - 1)].id
}

# attach private subnet to route table
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
