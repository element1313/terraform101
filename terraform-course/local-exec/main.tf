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

resource "aws_instance" "example" {


  provisioner "local-exec" {
    command = "echo ${self.id} >> myvmid"
  }
  ami           = "ami-078f95be0757084a3"
  instance_type = "t3.micro"
}


output "aws_instance_public_ip" {
  value = aws_instance.example.public_ip
}