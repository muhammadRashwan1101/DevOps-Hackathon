resource "aws_instance" "BackBenchers" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.BackBenchers_sg.id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = file("${path.module}/user_data.sh")

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-instance"
  })
}