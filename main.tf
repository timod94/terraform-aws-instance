provider "aws" {
    region = "eu-central-1"
}

# Generiere private und öffentliche SSH-Schlüssel
resource "tls_private_key" "private_key_tido" {
    algorithm = "RSA"
    rsa_bits  = 2048
}

# Speichern des privaten Schlüssels lokal mit den entsprechenden Berechtigungen
resource "local_file" "private_key" {
    content = tls_private_key.private_key_tido.private_key_pem
    filename = "${path.module}/id_rsa"
    file_permission = "0600"
}

# Erstelle einen öffentlichen Schlüssel und lade ihn in AWS hoch
resource "aws_key_pair" "tido_key" {
    key_name   = "tido-ssh-key"
    public_key = tls_private_key.private_key_tido.public_key_openssh
}

# Erstelle eine Security Group
resource "aws_security_group" "security_group_tido" {
    name        = "tido-security-group-1302"
    description = "Allow SSH and HTTP inbound traffic"
    vpc_id      = "vpc-0f98dde3dadf4a22e"  # Achte darauf, dass die VPC-ID korrekt ist
  
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Erstelle 3 EC2-Instanzen
resource "aws_instance" "my-ec2-instance" {
    count             = 3
    ami               = "ami-03b3b5f65db7e5c6f"  # Stelle sicher, dass diese AMI-ID in der Region verfügbar ist
    instance_type     = "t2.micro"
    key_name          = aws_key_pair.tido_key.key_name  # Verwendet das SSH-Schlüsselpaar
    security_groups   = [aws_security_group.security_group_tido.name]

    tags = {
        Name = "TidosInstance-${count.index + 1}"
    }
}
