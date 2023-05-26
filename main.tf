# Define the AWS provider and regions
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
  key_name      = "your_key_pair_name"
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

  # Enable DNS failover for routing
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false

  # Define health checks for the load balancer
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200-399"
    path                = "/"
    port                = 80
  }
}

resource "aws_lb" "load_balancer_us_east_2" {
  provider        = aws.us-east-2
  name            = "lb-us-east-2"
  subnets         = [aws_subnet.subnet_us_east_2.id]
  internal        = false
  security_groups = [aws_security_group.load_balancer_sg_us_east_2.id]

  # Enable DNS failover for routing
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false

  # Define health checks for the load balancer
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200-399"
    path                = "/"
    port                = 80
  }
}

# Configure health checks on the load balancers
resource "aws_lb_target_group" "target_group_us_east_1" {
  name     = "target-group-us-east-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_us_east_1.id

  # Configure health checks for the target group
  health_check {
    protocol               = "HTTP"
    port                   = 80
    interval               = 30
    timeout                = 5
    healthy_threshold      = 2
    unhealthy_threshold    = 2
    matcher                = "200"
    path                   = "/"
    enabled                = true
    unhealthy_http_codes   = "500,502,503,504"
    healthy_http_codes     = "200,301,302"
    health_check_path      = "/"
    health_check_port      = 80
    health_check_protocol  = "HTTP"
    health_check_interval  = 30
    health_check_timeout   = 5
    health_check_threshold = 2
    # success_codes          = "200"
   
    # target_type            = "instance"
  }
}

resource "aws_lb_target_group" "target_group_us_east_2" {
  provider = aws.us-east-2
  name     = "target-group-us-east-2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_us_east_2.id

  # Configure health checks for the target group
  health_check {
    protocol               = "HTTP"
    port                   = 80
    interval               = 30
    timeout                = 5
    healthy_threshold      = 2
    unhealthy_threshold    = 2
    matcher                = "200"
    path                   = "/"
    enabled                = true
    unhealthy_http_codes   = "500,502,503,504"
  }
}



# Create listeners on the load balancers
resource "aws_lb_listener" "listener_us_east_1" {
  load_balancer_arn = aws_lb.load_balancer_us_east_1.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_us_east_1.arn
  }
}

resource "aws_lb_listener" "listener_us_east_2" {
  provider          = aws.us-east-2
  load_balancer_arn = aws_lb.load_balancer_us_east_2.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_us_east_2.arn
  }
}

# Configure DNS routing
resource "aws_route53_zone" "route53_zone" {
  name = "example.com."
}

resource "aws_route53_record" "route53_record_us_east_1" {
  zone_id = aws_route53_zone.route53_zone.zone_id
  name    = "example.com"
  type    = "A"

  alias {
    name                   = aws_lb.load_balancer_us_east_1.dns_name
    zone_id                = aws_lb.load_balancer_us_east_1.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "route53_record_us_east_2" {
  zone_id = aws_route53_zone.route53_zone.zone_id
  name    = "example.com"
  type    = "A"

  alias {
    name                   = aws_lb.load_balancer_us_east_2.dns_name
    zone_id                = aws_lb.load_balancer_us_east_2.zone_id
    evaluate_target_health = true
  }
}

# Configure CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "cloudwatch_alarm_us_east_1" {
  alarm_name          = "high-cpu-usage-us-east-1"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors CPU usage on the instances in US East 1."
  alarm_actions       = ["arn:aws:sns:us-east-1:123456789012:my-sns-topic"]
  dimensions = {
    InstanceId = aws_autoscaling_group.autoscaling_group_us_east_1.id
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch_alarm_us_east_2" {
  provider            = aws.us-east-2
  alarm_name          = "high-cpu-usage-us-east-2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors CPU usage on the instances in US East 2."
  alarm_actions       = ["arn:aws:sns:us-east-2:123456789012:my-sns-topic"]
  dimensions = {
    InstanceId = aws_autoscaling_group.autoscaling_group_us_east_2.id
  }
}
