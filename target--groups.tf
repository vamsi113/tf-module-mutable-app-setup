resource "aws_lb_target_group" "main" {
  name     = "${var.env}-${var.name}-tg"
  port     = var.app_port_no
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    enabled = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 6
    path                = "/health"
  }
}

resource "aws_lb_listener_rule" "rule" {
  count = var.type == "backend" ? 1 : 0
  listener_arn = var.alb["private"].lb_listner_arn
  priority     = var.lb_listner_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    host_header {
      values = ["${var.name}-${var.env}.roboshop.internal"]
    }
  }
}

resource "aws_lb_listener_rule" "rule-frontend" {
  count = var.type == "frontend" ? 1 : 0
  listener_arn = var.alb["public"].lb_listner_arn
  priority     = var.lb_listner_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    host_header {
      values = ["${var.env}.vsudd67.online"]
    }
  }
}

resource "aws_lb_listener" "public-https" {
  count =  var.type == "frontend" ? 1: 0
  load_balancer_arn = var.alb["public"].lb_arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ACM_ARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}