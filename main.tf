provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "us-east-2"
  region = "us-east-2"
}

# Define your IP address
variable "keypair" {
  description = "ssh-key"
  default     = "sreuniversity"  # Replace with your actual keypair name
}

# Define your IP address
variable "my_ip_address" {
  description = "Your IP address"
  default     = "70.224.95.9/32"  # Replace with your actual IP address
}

# Create VPCs in each region
resource "aws_vpc" "vpc_us_east_1" {
  provider = aws

  cidr_block = "10.0.0.0/16"
}

resource "aws_vpc" "vpc_us_east_2" {
  provider   = aws.us-east-2

  cidr_block = "10.2.0.0/16"  # Modified CIDR block
}

# Create internet gateways
resource "aws_internet_gateway" "igw_us_east_2" {
  provider = aws.us-east-2

  vpc_id = aws_vpc.vpc_us_east_2.id
}

# Attach internet gateway to VPC
resource "aws_internet_gateway_attachment" "attachment_us_east_2" {
  provider = aws.us-east-2

  vpc_id             = aws_vpc.vpc_us_east_2.id
  internet_gateway_id = aws_internet_gateway.igw_us_east_2.id
}

# Create subnets in each VPC
resource "aws_subnet" "subnet_us_east_1a" {
  provider = aws

  vpc_id            = aws_vpc.vpc_us_east_1.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet_us_east_1b" {
  provider = aws

  vpc_id            = aws_vpc.vpc_us_east_1.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "subnet_us_east_2a" {
  provider = aws.us-east-2

  vpc_id            = aws_vpc.vpc_us_east_2.id
  cidr_block        = "10.2.1.0/24"  # Modified CIDR block
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "subnet_us_east_2b" {
  provider = aws.us-east-2

  vpc_id            = aws_vpc.vpc_us_east_2.id
  cidr_block        = "10.2.2.0/24"  # Modified CIDR block
  availability_zone = "us-east-2b"
}

# Create load balancers in each region
resource "aws_lb" "load_balancer_us_east_1" {
  provider = aws

  name               = "lb-us-east-1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.security_group_us_east_1.id]
  subnets            = [aws_subnet.subnet_us_east_1a.id, aws_subnet.subnet_us_east_1b.id]
}

resource "aws_lb" "load_balancer_us_east_2" {
  provider = aws.us-east-2

  name               = "lb-us-east-2"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.security_group_us_east_2.id]
  subnets            = [aws_subnet.subnet_us_east_2a.id, aws_subnet.subnet_us_east_2b.id]
}

# Create security groups for the instances and load balancers
resource "aws_security_group" "security_group_us_east_1" {
  provider = aws

  vpc_id = aws_vpc.vpc_us_east_1.id

  # Define inbound rules
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address]
  }

  # Define outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "security_group_us_east_2" {
  provider = aws.us-east-2

  vpc_id = aws_vpc.vpc_us_east_2.id

  # Define inbound rules
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address]
  }

  # Define outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create instances in each region
resource "aws_instance" "instance_us_east_1" {
  provider = aws

  ami                       = "ami-053b0d53c279acc90"
  instance_type             = "t2.micro"
  key_name                  = var.keypair
  subnet_id                 = aws_subnet.subnet_us_east_1a.id
  vpc_security_group_ids    = [aws_security_group.security_group_us_east_1.id]
  associate_public_ip_address = true
}

resource "aws_instance" "instance_us_east_2" {
  provider = aws.us-east-2

  ami                       = "ami-024e6efaf93d85776"
  instance_type             = "t2.micro"
  key_name                  = var.keypair
  subnet_id                 = aws_subnet.subnet_us_east_2a.id
  vpc_security_group_ids    = [aws_security_group.security_group_us_east_2.id]
  associate_public_ip_address = true
}
