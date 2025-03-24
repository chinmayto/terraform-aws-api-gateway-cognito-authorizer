# Securing API Gateway with Lambda Authorizer Using JWT Tokens


### Introduction


### Architecture
Follwing is the serverless architecture we will be dealing with.



### Steps to Run Terraform
Follow these steps to execute the Terraform configuration:
```terraform
terraform init
terraform plan 
terraform apply -auto-approve
```

Upon successful completion, Terraform will provide relevant outputs.
```terraform
Apply complete! Resources: 46 added, 0 changed, 0 destroyed.
```

### Testing


### Cleanup
Remember to stop AWS components to avoid large bills.
```terraform
terraform destroy -auto-approve
```

### Conclusion

### References
1. GitHub Repo: https://github.com/chinmayto/terraform-aws-api-gateway-lambda-authorizer
