########################################################################################
# AWS Cognito User Pool
########################################################################################
resource "aws_cognito_user_pool" "pool" {
  name = "mypool"
}

########################################################################################
# Create a user
########################################################################################
resource "aws_cognito_user" "example" {
  user_pool_id = aws_cognito_user_pool.pool.id
  username     = "chinmayto"
  password     = "Test@123"
}


resource "aws_cognito_resource_server" "resource_server" {
  name         = "cognito_resource_server"
  identifier   = "https://api.chinmayto.com"
  user_pool_id = aws_cognito_user_pool.pool.id

  scope {
    scope_name        = "all"
    scope_description = "Get access to all API Gateway endpoints."
  }
}


resource "aws_cognito_user_pool_domain" "main" {
  domain          = "auth.chinmayto.com"
  certificate_arn = aws_acm_certificate.my_api_cert.arn
  user_pool_id    = aws_cognito_user_pool.pool.id

  depends_on = [aws_acm_certificate_validation.cert_validation]
}


########################################################################################
# Create a user pool client
########################################################################################
/*
resource "aws_cognito_user_pool_client" "client" {
  name                                 = "client"
  allowed_oauth_flows_user_pool_client = true
  generate_secret                      = false
  allowed_oauth_scopes                 = ["aws.cognito.signin.user.admin", "email", "openid", "profile"]
  allowed_oauth_flows                  = ["implicit", "code"]
  explicit_auth_flows                  = ["ADMIN_NO_SRP_AUTH", "USER_PASSWORD_AUTH"]
  supported_identity_providers         = ["COGNITO"]

  user_pool_id  = aws_cognito_user_pool.pool.id
  callback_urls = ["https://example.com"]
  logout_urls   = ["https://chinmayto.com"]
}

*/

resource "aws_cognito_user_pool_client" "client" {
  name                                 = "cognito_client"
  user_pool_id                         = aws_cognito_user_pool.pool.id
  generate_secret                      = true
  allowed_oauth_flows                  = ["client_credentials"]
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = [aws_cognito_resource_server.resource_server.scope_identifiers[0]]

  depends_on = [aws_cognito_user_pool.pool, aws_cognito_resource_server.resource_server]
}