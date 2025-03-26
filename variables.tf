variable "aws_region" {
  type        = string
  description = "AWS region to use for resources."
  default     = "us-east-1"
}

variable "company" {
  type        = string
  description = "Company name for resource tagging"
  default     = "CT"
}

variable "project" {
  type        = string
  description = "Project name for resource tagging"
  default     = "Project"
}

variable "naming_prefix" {
  type        = string
  description = "Naming prefix for all resources."
  default     = "Demo"
}

variable "environment" {
  type        = string
  description = "Environment for deployment"
  default     = "dev"
}


variable "domain_name" {
  type        = string
  description = "DNS domain in the AWS account which you own or is linked via NS records to a DNS zone you own."
  default     = "chinmayto.com"
}

## API Gateway variables

variable "authorization_scopes" {
  type        = string
  description = "Authorization Scope for API Gateway"
  default     = "myapi/all"
}

 