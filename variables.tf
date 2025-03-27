variable "aws_region" {
  type        = string
  description = "AWS region to use for resources."
  default     = "us-east-1"
}

variable "domain_name" {
  type        = string
  description = "DNS domain in the AWS account which you own or is linked via NS records to a DNS zone you own."
  default     = "chinmayto.com"
}

variable "authorization_scopes" {
  type        = string
  description = "Authorization Scope for API Gateway"
  default     = "myapi/all"
}

 