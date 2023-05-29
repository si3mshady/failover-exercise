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
  # default     = "70.224.95.9/32"  # Replace with your actual IP address
  default = "174.242.222.72/32"
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
    cidr_blocks = [var.my_ip_address]
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



# # Create launch templates for autoscaling group
# resource "aws_launch_template" "launch_template_us_east_1" {
#   provider = aws


#   name                   = "lt-us-east-1"
#   image_id               = "ami-053b0d53c279acc90"
#   instance_type          = "t2.micro"
#   key_name               = var.keypair
#   # depends_on             = [aws_security_group.security_group_us_east_1]
#   # vpc_security_group_ids = [aws_security_group.security_group_us_east_1.id]  # Add security group name here

#   user_data              = base64encode(<<-EOT
#       #!/bin/bash
#       wget  https://raw.githubusercontent.com/si3mshady/failover-exercise/main/setup.sh
#       sudo chmod +x ./setup.sh
#       sudo bash ./setup.sh

#       wget https://raw.githubusercontent.com/si3mshady/failover-exercise/main/run_flask_app.sh
#       sudo chmod +x ./run_flask_app.sh
#       sudo bash ./run_flask_app.sh
#       EOT
#   )
#     network_interfaces {
#     associate_public_ip_address = true
#     security_groups = [aws_security_group.security_group_us_east_1.id]
#   }

# }


# resource "aws_launch_template" "launch_template_us_east_2" {
#   provider = aws.us-east-2

#   name                   = "lt-us-east-2"
#   image_id               = "ami-024e6efaf93d85776"
#   instance_type          = "t2.micro"
#   key_name               = var.keypair
  
#   # vpc_security_group_ids   = [aws_security_group.security_group_us_east_2.id]

#   user_data              = base64encode(<<-EOT
#     #!/bin/bash
#     wget  https://raw.githubusercontent.com/si3mshady/failover-exercise/main/setup.sh
#     sudo chmod +x ./setup.sh
#     sudo bash ./setup.sh


#     wget https://raw.githubusercontent.com/si3mshady/failover-exercise/main/run_flask_app.sh
#     sudo chmod +x ./run_flask_app.sh
#     sudo bash ./run_flask_app.sh
#     EOT
#   )
#     network_interfaces {
#     associate_public_ip_address = true
#     security_groups = [aws_security_group.security_group_us_east_2.id]
#   }

# }

resource "aws_lb_target_group" "target_group_us_east_2" {
  provider = aws.us-east-2

  name        = "tg-us-east-2"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_us_east_2.id
  # target_type = "instance"
  
  # for_each = aws_launch_template.launch_template_us_east_2.instances
  
  # launch_template_arn =  aws_launch_template.launch_template_us_east_2.arn

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

# # Create autoscaling group using launch templates
# resource "aws_autoscaling_group" "autoscaling_group_us_east_1" {
#   provider             = aws
#   desired_capacity     = 1
#   max_size             = 4
#   min_size             = 1
#   launch_template       {
#     id      = aws_launch_template.launch_template_us_east_1.id
#     version = "$Latest"
#   }
#   vpc_zone_identifier = [aws_subnet.subnet_us_east_1a.id, aws_subnet.subnet_us_east_1b.id]
# }

# resource "aws_autoscaling_group" "autoscaling_group_us_east_2" {
#   provider             = aws.us-east-2
#   desired_capacity     = 1
#   max_size             = 4
#   min_size             = 1
#   launch_template   {
#     id      = aws_launch_template.launch_template_us_east_2.id
#     version = "$Latest"
#   }
#   vpc_zone_identifier = [aws_subnet.subnet_us_east_2a.id, aws_subnet.subnet_us_east_2b.id]
# }

# Define target groups for load balancers
resource "aws_lb_target_group" "target_group_us_east_1" {
  provider = aws

  name        = "tg-us-east-1"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_us_east_1.id
  # target_type = "instance"

  # launch_template_arn =  aws_launch_template.launch_template_us_east_1.arn

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
 
  protocol          = "HTTP"


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