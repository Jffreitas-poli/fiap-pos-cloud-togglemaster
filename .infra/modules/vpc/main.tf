# VPC com sub-redes públicas e privadas multi-AZ
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "tc-${var.env}-vpc" }
}

resource "aws_subnet" "sn_public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true
  availability_zone       = each.value.az
  tags                    = { Name = "tc-${var.env}-sn-public-${each.value.az}" }
}

resource "aws_subnet" "sn_private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = { Name = "tc-${var.env}-sn-private-${each.value.az}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "tc-${var.env}-igw" }
}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "tc-${var.env}-rtb-public" }
}

resource "aws_route_table_association" "rtb_public_assoc" {
  for_each = aws_subnet.sn_public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rtb_public.id
}

resource "aws_nat_gateway" "ngw" {
  vpc_id            = aws_vpc.vpc.id
  availability_mode = "regional"
  tags              = { Name = "tc-${var.env}-ngw" }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "rtb_private" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
  tags = { Name = "tc-${var.env}-rtb-private" }
}

resource "aws_route_table_association" "rtb_private_assoc" {
  for_each = aws_subnet.sn_private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rtb_private.id
}