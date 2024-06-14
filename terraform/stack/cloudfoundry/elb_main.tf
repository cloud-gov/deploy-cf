resource "aws_lb" "cf" {
  name            = "${var.stack_description}-cloudfoundry"
  subnets         = module.vpc.public_subnet_ids
  security_groups = [module.vpc.web_traffic_security_group]
  ip_address_type = "dualstack"
  idle_timeout    = 3600

  enable_deletion_protection = true

  # module currently has hardcoded account ids
  # access_logs {
  #   bucket  = module.log_bucket.elb_bucket_name
  #   prefix  = var.stack_description
  #   enabled = true
  # }
}

# resource "aws_lb_target_group" "cf_gr_target_https" {
#   name     = "${var.stack_description}-cf-gr-https"
#   port     = 10443
#   protocol = "HTTPS"
#   vpc_id   = module.vpc.vpc_id

#   health_check {
#     healthy_threshold   = 2
#     interval            = 5
#     port                = 8443
#     timeout             = 4
#     unhealthy_threshold = 3
#     matcher             = 200
#     protocol            = "HTTPS"
#     path                = "/health"
#   }
# }

resource "aws_lb_target_group" "cf_target_https" {
  name     = "${var.stack_description}-cf-https"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = module.vpc.vpc_id

  health_check {
    healthy_threshold   = 2
    interval            = 5
    port                = 81
    timeout             = 4
    unhealthy_threshold = 3
    matcher             = 200
  }
}

resource "aws_lb_listener" "cf" {
  load_balancer_arn = aws_lb.cf.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Ext1-2021-06"
  certificate_arn   = data.aws_iam_server_certificate.wildcard_apps.arn

  default_action {
    target_group_arn = aws_lb_target_group.cf_target_https.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "cf_http" {
  load_balancer_arn = aws_lb.cf.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.cf_target_https.arn
  }
}

# resource "aws_wafv2_web_acl_association" "cf_waf_core" {
#   resource_arn = aws_lb.cf.arn
#   web_acl_arn  = aws_wafv2_web_acl.cf_uaa_waf_core.arn
# }