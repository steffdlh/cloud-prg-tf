resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name        = "${local.project}-vpc"
    Environment = local.environment
  }
}

resource "aws_subnet" "private_subnet" {
  count                  = length(local.private_subnet_cidrs)
  vpc_id                 = aws_vpc.main.id
  cidr_block             = local.private_subnet_cidrs[count.index].cidr_block
  map_public_ip_on_launch= false
  availability_zone      = local.private_subnet_cidrs[count.index].az
  tags = {
    Name        = "${local.project}-private-subnet-${count.index}"
    Environment = local.environment
  }
}

resource "aws_subnet" "public_subnet" {
  count                  = length(local.public_subnet_cidrs)
  vpc_id                 = aws_vpc.main.id
  cidr_block             = local.public_subnet_cidrs[count.index].cidr_block
  map_public_ip_on_launch= true
  availability_zone      = local.public_subnet_cidrs[count.index].az
  tags = {
    Name        = "${local.project}-public-subnet-${count.index}"
    Environment = local.environment
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${local.project}-internet-gateway"
    Environment = local.environment
  }
}

resource "aws_eip" "nat_eip" {
  count      = length(local.public_subnet_cidrs)
  depends_on = [aws_internet_gateway.igw]
  vpc        = true

  tags = {
    Name        = "${local.project}-igw-ip"
    Environment = local.environment
  }
}

resource "aws_nat_gateway" "nat" {
  count         = length(local.public_subnet_cidrs)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id

  tags = {
    Name        = "${local.project}-nat-gateway-${count.index}"
    Environment = local.environment
  }
}

resource "aws_route_table" "public_rt" {
  count  = length(local.public_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "${local.project}-public-route-table-${count.index}"
    Environment = local.environment
  }
}

resource "aws_route_table_association" "public_rta" {
  count          = length(local.public_subnet_cidrs)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt[count.index].id
}

resource "aws_route_table" "private_rt" {
  count  = length(local.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name        = "${local.project}-private-route-table-${count.index}"
    Environment = local.environment
  }
}

resource "aws_route_table_association" "private_rta" {
  count          = length(local.private_subnet_cidrs)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}