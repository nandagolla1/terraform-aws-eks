module "ingress_alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "9.16.0"
  internal = false
  name    = "frontend-alb"
  vpc_id  = local.vpc_id
  subnets = local.public_subnets
  create_security_group = false
  security_groups = [local.frontend_sg]

  enable_deletion_protection = false
  
  tags = merge(
    local.local_tags,
    {
        Name = "${var.project}-${var.environment}-${var.ingress_alb_sg_name}"
    }
  )
}

resource "aws_lb_listener" "ingress_alb_listener" {
  load_balancer_arn = module.ingress_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = local.acm_certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<h1>Hi I'm from from frontend alb</h1>"
      status_code  = "200"
    }
  }
}


resource "aws_route53_record" "ingress_alb" {
  zone_id = var.zone_id
  name    = "${var.environment}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.ingress_alb.dns_name
    zone_id                = module.ingress_alb.zone_id
    evaluate_target_health = true
  }
  allow_overwrite = true
}