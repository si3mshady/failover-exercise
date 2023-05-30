provider "aws" {
 
  region = "us-east-1"
  
}


provider "aws" {
  alias  = "us-east-2"
  region = "us-east-2"
}

#define hosted  zone
variable "hostedzone" {
  description = "hostedzone"
  default     = "Z08654031QGJY8UEMAS55"  # Replace with your actual keypair name
}

#define domain name
variable "domainname" {
  description = "domainname"
  default     = "sreuniversity.org"  # Replace with your actual keypair name
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
  # default = "174.242.222.72/32"
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

resource "aws_internet_gateway" "igw_us_east_1" {
  provider = aws
  vpc_id = aws_vpc.vpc_us_east_1.id
}

# Create internet gateways
resource "aws_internet_gateway" "igw_us_east_2" {
  provider = aws.us-east-2

  vpc_id = aws_vpc.vpc_us_east_2.id
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


resource "aws_route_table" "route_table_us_east_1" {
  provider = aws
  vpc_id = aws_vpc.vpc_us_east_1.id
}

resource "aws_route_table" "route_table_us_east_2" {
  provider = aws.us-east-2
  vpc_id = aws_vpc.vpc_us_east_2.id
}



resource "aws_route" "route_to_igw_us_east_1" {
  provider = aws
  route_table_id         = aws_route_table.route_table_us_east_1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_us_east_1.id
}

resource "aws_route" "route_to_igw_us_east_2" {
  provider = aws.us-east-2
  route_table_id         = aws_route_table.route_table_us_east_2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_us_east_2.id
}


resource "aws_route_table_association" "subnet_association_us_east_1a" {
  provider = aws
  subnet_id      = aws_subnet.subnet_us_east_1a.id
  route_table_id = aws_route_table.route_table_us_east_1.id
}

resource "aws_route_table_association" "subnet_association_us_east_1b" {
  provider = aws
  subnet_id      = aws_subnet.subnet_us_east_1b.id
  route_table_id = aws_route_table.route_table_us_east_1.id
}

resource "aws_route_table_association" "subnet_association_us_east_2a" {
  provider = aws.us-east-2
  subnet_id      = aws_subnet.subnet_us_east_2a.id
  route_table_id = aws_route_table.route_table_us_east_2.id
}

resource "aws_route_table_association" "subnet_association_us_east_2b" {
  provider = aws.us-east-2
  subnet_id      = aws_subnet.subnet_us_east_2b.id
  route_table_id = aws_route_table.route_table_us_east_2.id
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

  ingress {
    from_port   = 80
    to_port     = 80
    
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # Define inbound rules
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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

  ingress {
    from_port   = 80
    to_port     = 80
    
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address]
  }


  ingress {
    from_port   = 8080
    to_port     = 8080
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



resource "aws_lb_target_group" "target_group_us_east_2" {
  provider = aws.us-east-2

  name        = "tg-us-east-2"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_us_east_2.id


  health_check {
    path = "/health"
    port        = 8080
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    # matcher = "200"
  }
}

# Create listeners for load balancers
resource "aws_lb_listener" "listener_us_east_1" {
  provider = aws

  load_balancer_arn = aws_lb.load_balancer_us_east_1.arn
  port              = 80
  protocol          = "HTTP"


  default_action {
    target_group_arn = aws_lb_target_group.target_group_us_east_1.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "target_group_us_east_1" {
  provider = aws

  name        = "tg-us-east-1"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_us_east_1.id

  health_check {
    path = "/health"
    port        = 8080
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
 
  }
}

resource "aws_lb_target_group_attachment" "attachment_us_east1" {
  provider = aws
  depends_on = [aws_lb_target_group.target_group_us_east_1 ]
  target_group_arn = aws_lb_target_group.target_group_us_east_1.arn
  target_id = aws_instance.instance_us_east_1.id
  port = 8080
  # target_id        = eaws_launch_template.launch_template_us_east_1.id #launch Template
  
}



resource "aws_lb_target_group_attachment" "attachment_us_east2" {
  provider = aws.us-east-2
  depends_on = [aws_lb_target_group.target_group_us_east_2 ]
  target_group_arn = aws_lb_target_group.target_group_us_east_2.arn
  
  target_id        =  aws_instance.instance_us_east_2.id
  port = 8080
}



resource "aws_lb_listener" "listener_us_east_2" {
  provider = aws.us-east-2
  port = 80

  load_balancer_arn = aws_lb.load_balancer_us_east_2.arn
 
  # protocol          = "HTTP"
  protocol = "HTTP"


  default_action {
    target_group_arn = aws_lb_target_group.target_group_us_east_2.arn
    type             = "forward"
  }
}

# Create rules for load balancer listeners
resource "aws_lb_listener_rule" "listener_rule_us_east_1" {
  provider = aws

  listener_arn = aws_lb_listener.listener_us_east_1.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_us_east_1.arn
  }

  condition {
    # field  = "path-pattern"

    path_pattern {
       values = ["/"]
    }
   
  }
}

resource "aws_lb_listener_rule" "listener_rule_us_east_1_instance" {
  provider = aws

  listener_arn = aws_lb_listener.listener_us_east_1.arn
  priority     = 2

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_group_us_east_1.arn

    fixed_response {
      content_type = "text/plain"
      message_body = "Service temporarily unavailable."
      status_code  = "503"
    }
  }

  condition {
    # field  = "path-pattern"

    path_pattern {
       values = ["/health"]
    }
   
  }
}

resource "aws_lb_listener_rule" "listener_rule_us_east_2" {
  provider = aws.us-east-2

  listener_arn = aws_lb_listener.listener_us_east_2.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_us_east_2.arn
  }

   condition {
    # field  = "path-pattern"

    path_pattern {
       values = ["/"]
    }
   
  }
}

resource "aws_lb_listener_rule" "listener_rule_us_east_2_instance" {
  provider = aws.us-east-2

  listener_arn = aws_lb_listener.listener_us_east_2.arn
  priority     = 2

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_group_us_east_2.arn

    fixed_response {
      content_type = "text/plain"
      message_body = "Service temporarily unavailable."
      status_code  = "503"
    }
  }

  condition {
    # field  = "path-pattern"

    path_pattern {
       values = ["/health"]
    }
   
  }
}

resource "aws_eip" "eip1" {
  provider = aws
  depends_on = [ aws_instance.instance_us_east_2 ]
}

resource "aws_eip" "eip2" {
  provider = aws.us-east-2
  depends_on = [ aws_instance.instance_us_east_2 ]

}


resource "aws_eip_association" "my_eip_association_us_east_1" {
  provider = aws
  instance_id   =  aws_instance.instance_us_east_1.id
  allocation_id = aws_eip.eip1.id
}


resource "aws_eip_association" "my_eip_association_us_east_2" {
  provider = aws.us-east-2
  instance_id   = aws_instance.instance_us_east_2.id
  allocation_id = aws_eip.eip2.id
}


resource "aws_instance" "instance_us_east_1" {
  provider = aws
  instance_type = "t2.micro"
  ami = "ami-053b0d53c279acc90"
  subnet_id = aws_subnet.subnet_us_east_1a.id
  key_name = var.keypair
  depends_on = [ aws_security_group.security_group_us_east_1 ]

 
  security_groups = [aws_security_group.security_group_us_east_1.id]
 
  user_data = base64encode(<<-EOT
    #!/bin/bash
    wget  https://raw.githubusercontent.com/si3mshady/failover-exercise/main/setup.sh
    sudo chmod +x ./setup.sh
    sudo bash ./setup.sh


    wget https://raw.githubusercontent.com/si3mshady/failover-exercise/main/run_flask_app.sh
    sudo chmod +x ./run_flask_app.sh
    sudo bash ./run_flask_app.sh
    EOT
  )
   
}



resource "aws_instance" "instance_us_east_2" {
  provider = aws.us-east-2
  ami = "ami-024e6efaf93d85776"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet_us_east_2b.id
  # aws_subnet" "subnet_us_east_1a"
  key_name = var.keypair
  depends_on = [ aws_security_group.security_group_us_east_2 ]
  security_groups = [aws_security_group.security_group_us_east_2.id]
   
  user_data = base64encode(<<-EOT
    #!/bin/bash
    wget  https://raw.githubusercontent.com/si3mshady/failover-exercise/main/setup.sh
    sudo chmod +x ./setup.sh
    sudo bash ./setup.sh


    wget https://raw.githubusercontent.com/si3mshady/failover-exercise/main/run_flask_app.sh
    sudo chmod +x ./run_flask_app.sh
    sudo bash ./run_flask_app.sh
    EOT
  )


}


data "aws_elb_hosted_zone_id" "primary" {
  region = "us-east-1"
}


data "aws_elb_hosted_zone_id" "secondary" {
  region = "us-east-2"
}



resource "aws_route53_record" "primary" {
  provider = aws
  zone_id = var.hostedzone
  name    = var.domainname
  type    = "A"
  # ttl     = 300

  

   failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "primary"
  # records        = [aws_eip.eip1.public_ip]
  health_check_id = aws_route53_health_check.sreuniversity_check_primary.id

  alias {
    name                   =  aws_lb.load_balancer_us_east_1.dns_name
    zone_id                =  aws_lb.load_balancer_us_east_1.zone_id #"Z35SXDOTRQ7X7K" #https://docs.aws.amazon.com/general/latest/gr/elb.html
    evaluate_target_health = true
  }

}


resource "aws_route53_record" "secondary" {
   provider = aws.us-east-2
  zone_id = var.hostedzone
  name    = var.domainname
  type    = "A"
  # ttl     = 300

  

   failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "secondary"
  health_check_id = aws_route53_health_check.sreuniversity_check_secondary.id


   alias {
    name                   =  aws_lb.load_balancer_us_east_2.dns_name
    zone_id                =    aws_lb.load_balancer_us_east_2.zone_id #
    evaluate_target_health = true
  }


}

########HEALTH CHECKS############
resource "aws_route53_health_check" "sreuniversity_check_primary" {
  provider = aws
  ip_address        = aws_eip.eip1.public_ip
  port              = 8080
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "2"
  request_interval  = "10"

  tags = {
    Name = "route53-primary-health-check"
  }
}


resource "aws_route53_health_check" "sreuniversity_check_secondary" {
  provider = aws.us-east-2
  ip_address        = aws_eip.eip2.public_ip
  port              = 8080
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "2"
  request_interval  = "10"

  tags = {
    Name = "route53-secondary-health-check"
  }
}



# resource "aws_route53_health_check" "example_us_east_2" {
#   provider = aws.us-east-2

#   fqdn                = aws_lb.load_balancer_us_east_2.dns_name
#   port                = 80
#   type                = "HTTP"
#   resource_path       = "/health"
#   request_interval    = 30
#   failure_threshold   = 3
#   enable_sni          = false
#   measure_latency     = true
#   invert_healthcheck  = false
#   disabled            = false
#   insufficient_data_health_status = "LastKnownStatus"
# }


# https://stackoverflow.com/questions/71649984/issue-to-get-all-hosted-zone-id-of-aws-elb-through-terraform



# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record#alias

# aws elbv2 describe-load-balancers --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:335055665325:loadbalancer/app/lb-us-east-1/a0c2d29ae09838a6
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record#alias


output "elastic_ip1" {
  value = aws_eip.eip1.public_ip
}

output "elastic_ip2" {
  value = aws_eip.eip2.public_ip
}