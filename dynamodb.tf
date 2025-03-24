################################################################################
# Creating DynamoDB table
################################################################################
resource "aws_dynamodb_table" "books_table" {
  name           = "Books_Table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "book_id"

  attribute {
    name = "book_id"
    type = "S"
  }
}

################################################################################
# Creating DynamoDB table items
################################################################################
locals {
  json_data = file("${path.module}/books.json")
  books     = jsondecode(local.json_data)
}

resource "aws_dynamodb_table_item" "books" {
  for_each   = local.books
  table_name = aws_dynamodb_table.books_table.name
  hash_key   = aws_dynamodb_table.books_table.hash_key
  item       = jsonencode(each.value)
}

