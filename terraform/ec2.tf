resource "aws_key_pair" "deployer" {
  key_name   = "terra-automate-key"
  public_key = file("C:\\Users\\Fahad\\Desktop\\DevOps-MP\\terraform\\terraform-key.pub")
}

resource "aws_default_vpc" "default" {}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_default_vpc.default.id
}

resource "aws_route_table" "default" {
  vpc_id = aws_default_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "default-route-table"
  }
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-2a"]
  }
}

data "aws_subnet" "selected_subnet" {
  id = tolist(data.aws_subnets.default_subnets.ids)[0]
}

resource "aws_route_table_association" "default" {
  subnet_id      = data.aws_subnet.selected_subnet.id
  route_table_id = aws_route_table.default.id
}

resource "aws_security_group" "allow_user_to_connect" {
  name        = "allow TLS"
  description = "Allow user to connect"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "port 22 allow"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "port 80 allow"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "port 443 allow"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysecurity"
  }
}

resource "aws_instance" "testinstance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.allow_user_to_connect.id]
  associate_public_ip_address = true
  subnet_id                   = data.aws_subnet.selected_subnet.id

  tags = {
    Name = "Automate"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
}
