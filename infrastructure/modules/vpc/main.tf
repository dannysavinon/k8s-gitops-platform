locals {
  # Common tags for EKS auto-discovery of subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                        = var.name
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-igw"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    { Name = "${var.name}-public-${var.azs[count.index]}" },
    var.cluster_name != "" ? local.public_subnet_tags : {}
  )
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    { Name = "${var.name}-private-${var.azs[count.index]}" },
    var.cluster_name != "" ? local.private_subnet_tags : {}
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway (Simplified Logic: Single or One-Per-AZ)
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway && var.single_nat_gateway ? 1 : (var.enable_nat_gateway ? length(var.private_subnets) : 0)
  domain = "vpc"

  tags = {
    Name = "${var.name}-nat-${count.index}"
  }
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway && var.single_nat_gateway ? 1 : (var.enable_nat_gateway ? length(var.private_subnets) : 0)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id # Places NAT in public subnets 0, 1, 2...

  depends_on = [aws_internet_gateway.this]

  tags = {
    Name = "${var.name}-nat-${count.index}"
  }
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    # If single NAT, everyone uses index 0. If Multi NAT, use corresponding index.
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
  }

  tags = {
    Name = "${var.name}-private-${count.index}"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
