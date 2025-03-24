import os
import boto3
from botocore.exceptions import ClientError
from decimal import Decimal
import logging
import json

# Configure logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Define API paths
book_path = '/book'
books_path = '/books'

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.getenv('DYNAMODB_TABLE'))

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")
    
    try: 
        http_method = event.get('httpMethod')
        path = event.get('path')
        # Handle GET Request - Fetch All Books
        if http_method == 'GET' and path == books_path:
            return get_all_books()
            
        # Handle GET Request - Fetch a Single Book
        elif http_method == 'GET' and path == book_path:
            params = event.get('queryStringParameters')
            if not params or 'book_id' not in params:
                return generate_response(400, 'Missing required parameter: book_id')

            return get_book(params['book_id'])
        
        # Handle POST Request - Save a New Book
        elif http_method == 'POST' and path == book_path:
            body = parse_request_body(event)
            if not body or 'book_id' not in body:
                return generate_response(400, 'Missing required field: book_id')
            
            return save_book(body)
            
        # Handle PATCH Request - Update a Book
        elif http_method == 'PATCH' and path == book_path:
            body = parse_request_body(event)
            if not body or 'book_id' not in body or 'update_key' not in body or 'update_value' not in body:
                return generate_response(400, 'Missing required fields: book_id, update_key, update_value')
            
            return update_book(body['book_id'], body['update_key'], body['update_value'])
            
        # Handle DELETE Request - Delete a Book
        elif http_method == 'DELETE':
            body = parse_request_body(event)
            if not body or 'book_id' not in body:
                return generate_response(400, 'Missing required field: book_id')
            
            return delete_book(body['book_id'])

        return generate_response(404, 'Resource Not Found')
                
    except ClientError as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        return generate_response(500, 'Internal Server Error')

# Handle GET Request - Fetch a Single Book
def get_book(book_id):
    try:
        response = table.get_item(Key={'book_id': book_id})
        if 'Item' not in response:
            logger.warning(f"Book not found: {book_id}")
            return generate_response(404, f'Book with ID {book_id} not found')

        logger.info(f"GET book: {response['Item']}")
        return generate_response(200, response['Item'])

    except ClientError as e:
        logger.error(f"DynamoDB error: {e.response['Error']['Message']}", exc_info=True)
        return generate_response(500, 'Error fetching book from database')

# Handle GET Request - Fetch All Books
def get_all_books():
    try:
        scan_params = {
            'TableName': table.name
        }
        items = recursive_scan(scan_params, [])
        logger.info('GET ALL items: {}'.format(items))
        return generate_response(200, items)
    
    except ClientError as e:
        logger.error(f"DynamoDB error: {e.response['Error']['Message']}", exc_info=True)
        return generate_response(500, 'Error fetching books from database')

# Recursive function to scan all items in DynamoDB table    
def recursive_scan(scan_params, items):
    response = table.scan(**scan_params)
    items += response['Items']
    if 'LastEvaluatedKey' in response:
        scan_params['ExclusiveStartKey'] = response['LastEvaluatedKey']
        recursive_scan(scan_params, items)
    return items

# Handle POST Request - Save a New Book
def save_book(item):
    try:
        response = table.put_item(Item=item)
        return generate_response(201, {'Message': 'Book saved successfully', 'Item': item})

    except ClientError as e:
        logger.error(f"DynamoDB error: {e.response['Error']['Message']}", exc_info=True)
        return generate_response(500, 'Error saving book')
    
# Handle PATCH Request - Update a Book    
def update_book(book_id, update_key, update_value):
    try:
        response = table.update_item(
            Key={'book_id': book_id},
            UpdateExpression=f'SET {update_key} = :value',
            ExpressionAttributeValues={':value': update_value},
            ConditionExpression='attribute_exists(book_id)',  # Ensure item exists
            ReturnValues='UPDATED_NEW'
        )
        return generate_response(200, {'Message': 'Book updated successfully', 'UpdatedAttributes': response['Attributes']})

    except ClientError as e:
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            logger.warning(f"Update failed: Book with ID {book_id} does not exist")
            return generate_response(404, f'Book with ID {book_id} not found')
        
        logger.error(f"DynamoDB error: {e.response['Error']['Message']}", exc_info=True)
        return generate_response(500, 'Error updating book')
    
# Handle DELETE Request - Delete a Book    
def delete_book(book_id):
    try:
        response = table.delete_item(
            Key={'book_id': book_id},
            ReturnValues='ALL_OLD'
        )
        if 'Attributes' not in response:
            return generate_response(404, f'Book with ID {book_id} not found')

        return generate_response(200, {'Message': 'Book deleted successfully', 'DeletedItem': response['Attributes']})

    except ClientError as e:
        logger.error(f"DynamoDB error: {e.response['Error']['Message']}", exc_info=True)
        return generate_response(500, 'Error deleting book')

# Helper functions - Parse Request Body and Generate Response
def parse_request_body(event):
    try:
        return json.loads(event.get('body', '{}'))
    except json.JSONDecodeError:
        return None

# Custom JSON Encoder to handle Decimal types
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            if obj % 1 == 0:
                return int(obj)
            else:
                return float(obj)
        return super(DecimalEncoder, self).default(obj)

# Generate API response
def generate_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({'status': status_code, 'data': body}, cls=DecimalEncoder)
    }