################################################################################
# Create an ACM certificate for the domain
################################################################################
resource "aws_acm_certificate" "my_api_cert" {
  domain_name = "*.chinmayto.com"
  # subject_alternative_names = ["auth.chinmayto.com", "*.api.chinmayto.com"]
  validation_method = "DNS"
}

################################################################################
# Get the hosted zone ID for the domain
################################################################################
data "aws_route53_zone" "my_domain" {
  name         = "chinmayto.com"
  private_zone = false
}

################################################################################
# Create a CNAME record for the API Gateway endpoint
################################################################################
resource "aws_route53_record" "custom_domain_record" {
  name = "api" # The subdomain (api.sumeet.life)
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
# Validate the certificate
################################################################################
resource "aws_acm_certificate_validation" "cert_validation" {
  timeouts {
    create = "5m"
  }
  certificate_arn         = aws_acm_certificate.my_api_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_record : record.fqdn]
}

################################################################################
# Create a domain name for the API Gateway endpoint
################################################################################
resource "aws_api_gateway_domain_name" "custom_domain" {

  depends_on = [aws_acm_certificate_validation.cert_validation]

  domain_name              = "api.chinmayto.com"
  regional_certificate_arn = aws_acm_certificate.my_api_cert.arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

################################################################################
# Create a base path mapping for the domain
################################################################################
resource "aws_api_gateway_base_path_mapping" "custom_domain_mapping" {
  domain_name = aws_api_gateway_domain_name.custom_domain.domain_name
  api_id      = aws_api_gateway_rest_api.API-gateway.id
  stage_name  = aws_api_gateway_stage.my-prod-stage.stage_name
}





# Required for Cognito Custom Domain validation
resource "aws_route53_record" "root_record" {
  name    = "chinmayto.com"
  type    = "A"
  zone_id = data.aws_route53_zone.my_domain.id

  alias {
    name                   = "chinmayto.com"
    zone_id                = "Z2FDTNDATAQYW2"   # CloudFront Zone ID
    evaluate_target_health = false
  }

  depends_on = [aws_route53_record.custom_domain_record]
}

resource "aws_route53_record" "auth-cognito-A" {
  name    = "auth.chinmayto.com"
  type    = "A"
  zone_id = data.aws_route53_zone.my_domain.zone_id
  alias {
    evaluate_target_health = false

    name                   = "auth.chinmayto.com"
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront Zone ID
  }
}

