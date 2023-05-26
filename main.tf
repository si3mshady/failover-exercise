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
  default     = "sreuniversity"  # Replace with your actual IP address
}

# Define your IP address
variable "my_ip_address" {
  description = "Your IP address"
  default     = "70.224.95.9/32"  # Replace with your actual IP address
}

# Create VPCs in each region
resource "aws_vpc" "vpc_us_east_1" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_vpc" "vpc_us_east_2" {
  cidr_block = "10.1.0.0/16"
  provider   = aws.us-east-2
}

# Create subnets in each VPC
resource "aws_subnet" "subnet_us_east_1" {
  vpc_id            = aws_vpc.vpc_us_east_1.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet_us_east_2" {
  vpc_id            = aws_vpc.vpc_us_east_2.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-east-2a"
  provider          = aws.us-east-2
}

# Create security groups for the instances and load balancers
resource "aws_security_group" "security_group_us_east_1" {
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
  vpc_id   = aws_vpc.vpc_us_east_2.id
  provider = aws.us-east-2

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

resource "aws_security_group" "load_balancer_sg_us_east_1" {
  vpc_id = aws_vpc.vpc_us_east_1.id

  # Define inbound rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Define outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "load_balancer_sg_us_east_2" {
  vpc_id   = aws_vpc.vpc_us_east_2.id
  provider = aws.us-east-2

  # Define inbound rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Define outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create launch templates in each region
resource "aws_launch_template" "launch_template_us_east_1" {
  name_prefix   = "lt-us-east-1-"
  image_id      = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  key_name      = var.keypair
  user_data     = "some_user_data"

  network_interfaces {
    security_groups = [aws_security_group.security_group_us_east_1.id]
    associate_public_ip_address = true
    subnet_id       = aws_subnet.subnet_us_east_1.id
  }
}

resource "aws_launch_template" "launch_template_us_east_2" {
  provider      = aws.us-east-2
  name_prefix   = "lt-us-east-2-"
  image_id      = "ami-024e6efaf93d85776"
  instance_type = "t2.micro"
  key_name      = var.keypair
  user_data     = "some_user_data"

  network_interfaces {
    security_groups = [aws_security_group.security_group_us_east_2.id]
    associate_public_ip_address = true
    subnet_id       = aws_subnet.subnet_us_east_2.id
  }
}

# Create Auto Scaling Groups in each region
resource "aws_autoscaling_group" "autoscaling_group_us_east_1" {
  name                      = "asg-us-east-1"
  max_size                  = 3
  min_size                  = 1
  desired_capacity          = 2

  launch_template {
    id      = aws_launch_template.launch_template_us_east_1.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.subnet_us_east_1.id]
}

resource "aws_autoscaling_group" "autoscaling_group_us_east_2" {
  provider                  = aws.us-east-2
  name                      = "asg-us-east-2"
  max_size                  = 3
  min_size                  = 1
  desired_capacity          = 2

  launch_template {
    id      = aws_launch_template.launch_template_us_east_2.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.subnet_us_east_2.id]
}

# Create load balancers in each region
resource "aws_lb" "load_balancer_us_east_1" {
  name            = "lb-us-east-1"
  subnets         = [aws_subnet.subnet_us_east_1.id]
  internal        = false
  security_groups = [aws_security_group.load_balancer_sg_us_east_1.id]
}

resource "aws_lb" "load_balancer_us_east_2" {
  provider        = aws.us-east-2
  name            = "lb-us-east-2"
  subnets         = [aws_subnet.subnet_us_east_2.id]
  internal        = false
  security_groups = [aws_security_group.load_balancer_sg_us_east_2.id]
}

# Create target groups and listeners in each region
resource "aws_lb_target_group" "target_group_us_east_1" {
  name     = "tg-us-east-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_us_east_1.id
}

resource "aws_lb_target_group" "target_group_us_east_2" {
  provider = aws.us-east-2
  name     = "tg-us-east-2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_us_east_2.id
}

resource "aws_lb_listener" "listener_us_east_1" {
  load_balancer_arn = aws_lb.load_balancer_us_east_1.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group_us_east_1.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "listener_us_east_2" {
  provider          = aws.us-east-2
  load_balancer_arn = aws_lb.load_balancer_us_east_2.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group_us_east_2.arn
    type             = "forward"
  }
}
