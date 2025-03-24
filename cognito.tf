########################################################################################
# AWS Cognito User Pool
########################################################################################
resource "aws_cognito_user_pool" "pool" {
  name = "mypool"
}
########################################################################################
# Create a user pool client
########################################################################################
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


########################################################################################
# Create a user
########################################################################################
resource "aws_cognito_user" "example" {
  user_pool_id = aws_cognito_user_pool.pool.id
  username     = "chinmayto"
  password     = "Test@123"
}




resource "aws_cognito_user_pool_domain" "main" {
  domain          = "auth.chinmayto.com"
  certificate_arn = aws_acm_certificate.my_api_cert.arn
  user_pool_id    = aws_cognito_user_pool.pool.id

  depends_on = [aws_acm_certificate_validation.cert_validation]
}
