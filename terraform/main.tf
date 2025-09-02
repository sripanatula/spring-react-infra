resource "aws_instance" "backend" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_az1.id
  vpc_security_group_ids      = [aws_security_group.backend_sg.id]
  key_name                    = var.ec2_key_name
  associate_public_ip_address = true
  tags = {
    Name = "${var.project_name}-backend"
  }
}