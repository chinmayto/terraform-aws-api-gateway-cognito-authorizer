################################################################################
# Get the hosted zone ID for the domain
################################################################################
data "aws_route53_zone" "my_domain" {
  name         = var.domain_name
  private_zone = false
}

################################################################################
# Create a CNAME record for the API Gateway endpoint
################################################################################
resource "aws_route53_record" "custom_domain_record" {
  name = "api" # The subdomain (api.chinmayto.com)
  type = "CNAME"
  ttl  = "300" # TTL in seconds

  records = ["${aws_api_gateway_rest_api.API-gateway.id}.execute-api.us-east-1.amazonaws.com"]

  zone_id = data.aws_route53_zone.my_domain.zone_id
}

################################################################################
# Create a certificate validation record for the domain
################################################################################
resource "aws_route53_record" "cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.my_api_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.my_domain.zone_id
}

################################################################################
# Create a record for the domain name
# Required for Cognito Custom Domain validation
################################################################################
resource "aws_route53_record" "root_record" {
  name    = var.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.my_domain.id
  ttl     = "300"

  records         = ["8.8.8.8"] #This can be any dummy IP address
  allow_overwrite = true
}

resource "aws_route53_record" "auth-cognito-A" {
  name    = "auth.${var.domain_name}"
  type    = "A"
  zone_id = data.aws_route53_zone.my_domain.zone_id

  alias {
    evaluate_target_health = false

    name    = aws_cognito_user_pool_domain.user_pool_domain.cloudfront_distribution_arn
    zone_id = "Z2FDTNDATAQYW2" # CloudFront Zone ID
  }
}

