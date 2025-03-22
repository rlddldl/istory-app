# Launch Template
resource "aws_launch_template" "istory_lt" {
  name_prefix   = "istory-lt"
  image_id      = "ami-08b09b6acd8d62254"
  instance_type = "t3.small"

  network_interfaces {
    associate_public_ip_address = true
    security_groups            = [aws_security_group.istory_prod_ec2_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y ruby wget
              cd /home/ec2-user
              wget https://aws-codedeploy-ap-northeast-2.s3.ap-northeast-2.amazonaws.com/latest/install
              chmod +x ./install
              ./install auto
              systemctl start codedeploy-agent
              systemctl enable codedeploy-agent
              cd /tmp
              wget https://corretto.aws/downloads/latest/amazon-corretto-17-x64-linux-jdk.rpm
              yum install -y amazon-corretto-17-x64-linux-jdk.rpm
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "istory-prod"
      Environment = "Production"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "istory_asg" {
  name                = "istory-asg"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  target_group_arns   = [aws_lb_target_group.istory_tg.arn]
  vpc_zone_identifier = [for subnet in aws_subnet.dangtong-vpc-public-subnet : subnet.id]

  launch_template {
    id      = aws_launch_template.istory_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Environment"
    value               = "Production"
    propagate_at_launch = true
  }
}