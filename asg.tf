resource "aws_launch_template" "launch-template" {
  name          = "${var.env}-${var.name}-lt"
  image_id      = data.aws_ami.centos-8-ami.image_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.sg.id]

  instance_market_options {
    market_type = "spot"
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }
  user_data = base64encode(templatefile("${path.module}/ansible-pull.sh", {
    COMPONENT = var.name
    ENV       = var.env
  }))
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.env}-${var.name}-asg"
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.subnets
  target_group_arns   = [aws_lb_target_group.main.arn]

  launch_template {
    id      = aws_launch_template.launch-template.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "${var.env}-${var.name}"
  }
  tag {
    key                 = "Monitor"
    propagate_at_launch = true
    value               = "yes"
  }
}

resource "aws_autoscaling_policy" "cpu-tracking-policy" {
  name        = "whenCPULoadIncrease"
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
  autoscaling_group_name = aws_autoscaling_group.asg.name
}