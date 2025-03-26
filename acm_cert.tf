################################################################################
# Create an ACM certificate for the domain
################################################################################
resource "aws_acm_certificate" "my_api_cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["auth.${var.domain_name}", "api.${var.domain_name}"]
  validation_method         = "DNS"
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