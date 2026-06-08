terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_key_pair" "deployer" {
  key_name   = "main-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCmnotdmy6gz9XIrQiFFnnEHafTxqKgb+GdTq2N8sIOTadn0OjY1BSD2sYojWGdH1NqeQF/1DXIFPx5rmgBpKkWNHoNFLtdA3uqueMMZorHY/KRJyH/iwSkSMX4J9XiXDGKtUN3gaccNLFvUesFMthNzHs76kBsK0Mk4y4S/DN+2Z7gnMUxOLVx9W2sWIpJMFARMO0IybbDTJlN5X5Y5EEGWT2HZsZtONxBkjqcEct4ccEdLLbV84XH8SLHaXB36iAAQeniKGWOQD4Gg1kptKGl4kcCg1mf4qizU4R58d7CwR1JdlHWMjks1nEEbcSZpwdCyVYPX0KIImdW2BqIID1p3CbGodBVarcjxsUuZdbGGUM9pV1OcJ9V8V5S8SEkk8Rdy8i5MxUpjtrI0qHIr4eX4fuqT19pNnquyaz4oad+O/sf/LI0nhouO7zjBrVwm+T9rSU0+hnuGtmp3CRLCJIatuUbmmZTMaHmB9rm1KKNJ2Q5MV3/PsI9WcbAdc1+/sE= ec2-user@ip-172-31-37-82.us-east-2.compute.internal"
}


variable "subnet_prefix" {
  #type        = string
  #default     = ""
  description = "cidr block for the subnet"
}


resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Production"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = var.subnet_prefix
  availability_zone = "us-east-2a"

  tags = {
    Name = "prod-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}



resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_tls"
  description = "Allow Web inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 443
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 443
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    }
  ]

  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]

  tags = {
    Name = "allow_web"
  }
}



# resource "aws_vpc_security_group_ingress_rule" "allow_https" {
#   security_group_id = aws_security_group.allow_web.id
#   cidr_ipv4         = aws_vpc.aws_vpc.prod-vpc.cidr_block
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_http" {
#   security_group_id = aws_security_group.allow_web.id
#   cidr_ipv4         = aws_vpc.aws_vpc.prod-vpc.cidr_block
#   from_port         = 80
#   ip_protocol       = "tcp"
#   to_port           = 80
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
#   security_group_id = aws_security_group.allow_web.id
#   cidr_ipv4         = aws_vpc.aws_vpc.prod-vpc.cidr_block
#   from_port         = 22
#   ip_protocol       = "tcp"
#   to_port           = 22
# }


# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
#   security_group_id = aws_security_group.allow_web.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.100.50"]
  security_groups = [aws_security_group.allow_web.id]

  # attachment {
  #   instance     = aws_instance.test.id
  #   device_index = 1
  # }
}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.100.50"
  depends_on                = [aws_internet_gateway.gw]
}

output "server_public_ip" {
  value = aws_eip.one.public_ip
}

resource "aws_instance" "web-server-instance" {
  ami               = "ami-0fe18bc3cfa53a248"
  instance_type     = "t3.micro"
  availability_zone = "us-east-2a"
  key_name          = "main-key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2 
              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF
  tags = {
    Name = "web-server"
  }

}

output "instance_id" {
  value = aws_instance.web-server-instance.id
}

resource "aws_route53_zone" "primary" {
  name = "uzbchess.com"
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "uzbchess.com"
  type    = "A"
  ttl     = 300
  records = [aws_eip.one.public_ip]
}




# resource "aws_subnet" "subnet-1" {
#   vpc_id     = aws_vpc.first-vpc.id
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "prod-subnet"
#   }
# }

# resource "aws_vpc" "first-vpc" {
#   cidr_block = "10.0.0.0/16"
#   tags = {
#     Name = "Production"
#   }
# }

# resource "aws_vpc" "second-vpc" {
#   cidr_block = "10.1.0.0/16"
#   tags = {
#     Name = "Dev"
#   }
# }
# resource "aws_subnet" "subnet-2" {
#   vpc_id     = aws_vpc.second-vpc.id
#   cidr_block = "10.1.1.0/24"

#   tags = {
#     Name = "dev-subnet"
#   }
# }
