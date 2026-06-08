provider "aws" {
   region     = "us-east-2"
   
}

resource "aws_instance" "ec2_example" {

    ami = "ami-078f95be0757084a3"  
    instance_type = "t3.micro" 
    key_name= "aws_key"
    vpc_security_group_ids = [aws_security_group.main.id]

  provisioner "file" {
    source      = "/home/ec2-user/aws/test-file.txt"
    destination = "/home/ec2-user/test-file.txt"
  }
  connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2-user"
      private_key = file("/home/ec2-user/aws/key")
      timeout     = "4m"
   }
}

resource "aws_security_group" "main" {
  egress = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
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
 ingress                = [
   {
     cidr_blocks      = [ "0.0.0.0/0", ]
     description      = ""
     from_port        = 22
     ipv6_cidr_blocks = []
     prefix_list_ids  = []
     protocol         = "tcp"
     security_groups  = []
     self             = false
     to_port          = 22
  }
  ]
}

resource "aws_key_pair" "deployer" {
  key_name   = "aws_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCmnotdmy6gz9XIrQiFFnnEHafTxqKgb+GdTq2N8sIOTadn0OjY1BSD2sYojWGdH1NqeQF/1DXIFPx5rmgBpKkWNHoNFLtdA3uqueMMZorHY/KRJyH/iwSkSMX4J9XiXDGKtUN3gaccNLFvUesFMthNzHs76kBsK0Mk4y4S/DN+2Z7gnMUxOLVx9W2sWIpJMFARMO0IybbDTJlN5X5Y5EEGWT2HZsZtONxBkjqcEct4ccEdLLbV84XH8SLHaXB36iAAQeniKGWOQD4Gg1kptKGl4kcCg1mf4qizU4R58d7CwR1JdlHWMjks1nEEbcSZpwdCyVYPX0KIImdW2BqIID1p3CbGodBVarcjxsUuZdbGGUM9pV1OcJ9V8V5S8SEkk8Rdy8i5MxUpjtrI0qHIr4eX4fuqT19pNnquyaz4oad+O/sf/LI0nhouO7zjBrVwm+T9rSU0+hnuGtmp3CRLCJIatuUbmmZTMaHmB9rm1KKNJ2Q5MV3/PsI9WcbAdc1+/sE= ec2-user@ip-172-31-37-82.us-east-2.compute.internal"
}



