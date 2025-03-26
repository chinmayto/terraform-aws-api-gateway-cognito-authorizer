################################################################################
# AWS Cognito User Pool
################################################################################
resource "aws_cognito_user_pool" "my_cognito_user_pool" {
  name = "my_cognito_user_pool"
}

################################################################################
# Create a user
################################################################################
resource "aws_cognito_user" "example" {
  user_pool_id = aws_cognito_user_pool.my_cognito_user_pool.id
  username     = "chinmayto"
  password     = "Test@123"
}

################################################################################
# Create a domain for the user pool
################################################################################
resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain          = "auth.${var.domain_name}"
  certificate_arn = aws_acm_certificate.my_api_cert.arn
  user_pool_id    = aws_cognito_user_pool.my_cognito_user_pool.id

  depends_on = [aws_acm_certificate_validation.cert_validation]
}

################################################################################
# Create a user pool client
################################################################################
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                                 = "cognito_client"
  user_pool_id                         = aws_cognito_user_pool.my_cognito_user_pool.id
  generate_secret                      = true
  allowed_oauth_flows                  = ["client_credentials"]
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = [aws_cognito_resource_server.resource_server.scope_identifiers[0]]

  depends_on = [aws_cognito_user_pool.my_cognito_user_pool, aws_cognito_resource_server.resource_server]
}

################################################################################
# Create a resource server
################################################################################
resource "aws_cognito_resource_server" "resource_server" {
  name         = "cognito_resource_server"
  identifier   = "myapi"
  user_pool_id = aws_cognito_user_pool.my_cognito_user_pool.id

  scope {
    scope_name        = "all"
    scope_description = "Get access to all API Gateway endpoints."
  }
}
