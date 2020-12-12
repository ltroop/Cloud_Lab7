provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_vpc" "l7_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
      Name = "Lab7"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.l7_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    "Name" = "Lab7_1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.l7_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"
  


  tags = {
    "Name" = "Lab7_2"
  }
}

resource "aws_network_acl" "l7_net" {
  vpc_id = aws_vpc.l7_vpc.id

  ingress {
    protocol   = "all"
    rule_no    = 200
    action     = "deny"
    cidr_block = "50.31.252.0/24"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_internet_gateway" "GW7" {
  vpc_id = aws_vpc.l7_vpc.id

  tags = {
    Name = "L7_Gateway"
  }
}

resource "aws_route_table" "l7route" {
  vpc_id = aws_vpc.l7_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.GW7.id
  }

  tags = {
    Name = "L7Route"
  }
}


resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.l7route.id
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.l7route.id
}


resource "aws_security_group" "l7_sg_db" {
  name   = "Lab7"
  vpc_id = aws_vpc.l7_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Lab7SecGroup"
  }
}

resource "aws_db_subnet_group" "db_subnets" {
  name = "lab_seven"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "L7DBSubnets"
  }
}

resource "aws_db_instance" "rds_db" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "dbtest"
  username               = "*****"
  password               = "*****"
  publicly_accessible    = true
  skip_final_snapshot = true
  parameter_group_name   = "default.mysql5.7"
  vpc_security_group_ids = [aws_security_group.l7_sg_db.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.id
}


