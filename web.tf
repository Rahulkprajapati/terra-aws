//AWS provider
provider "aws" {
  region     = "ap-south-1"
  profile    = "myrahul"
}

//security group creation for firewall

resource "aws_security_group" "mysecurity" {
  name        = "terra_security"
  description = "Allow SSH and HTTP "


  ingress {
    description = "allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


 ingress {
    description = "allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "terra_security"
  }
}

//instance creation
resource "aws_instance" "myweb" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "mycloudkey1"
  security_groups = [ "mysecurity" ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Rahul Prajapati/Desktop/awswk/mycloudkey1.pem")
    host     = aws_instance.myweb.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "LoanCalculator"
  }

}

//EBS volume creation
resource "aws_ebs_volume" "ebs1" {
  availability_zone = aws_instance.myweb.availability_zone
  size              = 1


  tags = {
    Name = "terra_myweb_ebs"
  }
}

//Attach Volume to Instance

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs1.id
  instance_id = aws_instance.myweb.id
  force_detach = true
}


output "myos_ip" {
  value = aws_instance.myweb.public_ip
}



//mounting the external Storage device(like pen drive) and creating partitions in cloning the my html page code

resource "null_resource" "nullremote"  {
depends_on = [
    aws_volume_attachment.ebs_att,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Rahul Prajapati/Desktop/awswk/mycloudkey1.pem")
    host     = aws_instance.myweb.public_ip
    }


  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/Rahulkprajapati/Terraformwebpage.git /var/www/html/"
    ]
  }
}

//s3 volume creation

resource "aws_s3_bucket" "s3rkpbckt" {
    bucket = "s3rkpbckt"
    acl    = "public-read"


    tags = {
	Name    = "indexpage-s3-bucket"
	
    }
    versioning {
	enabled =true
    }

}




//creating Snapshot for Image

resource "aws_ebs_snapshot" "mysnapshot" {
  volume_id = aws_ebs_volume.ebs1.id

  tags = {
    Name = "Configured_snap"
  }
}

//automatic opening the site over chrome brow


resource "null_resource" "nu1" {
depends_on = [
    null_resource.nullremote,
  ]

	provisioner "local-exec" {
	    command = "chrome  ${aws_instance.myweb.public_ip}"
  	}
}
