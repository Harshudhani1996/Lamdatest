# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda (Allow Access to S3)
resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "lambda_s3_policy"
  description = "Allow Lambda to read/write S3 objects"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::filesread",
          "arn:aws:s3:::filesread/*"
        ]
      }
    ]
  })
}

# Attach Policy to Role
resource "aws_iam_policy_attachment" "lambda_s3_attach" {
  name       = "lambda_s3_attach"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

# Validation Lambda Function
resource "aws_lambda_function" "validate_file_lambda" {
  function_name    = "validate_file_lambda"
  runtime         = "python3.9"
  handler         = "validation.lambda_handler"
  filename        = "validation_lambda.zip"
  source_code_hash = filebase64sha256("validation_lambda.zip")
  role            = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      BUCKET_NAME       = "filesread"
      VALIDATED_FOLDER  = "Validatedfiles"   # ✅ Remove slash if needed
    }
  }
}

# S3 Trigger for Validation Lambda
resource "aws_s3_bucket_notification" "s3_event_validation" {
  bucket = aws_s3_bucket.filesread.id  # Ensure this matches your bucket resource

  lambda_function {
    lambda_function_arn = aws_lambda_function.validate_file_lambda.arn  # Corrected resource name
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "allfiles/"  # The source folder name
  }
}

# Permission for S3 to Invoke Lambda
resource "aws_lambda_permission" "s3_trigger_validation" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.validate_file_lambda.function_name  # Use the correct resource name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.filesread.arn  # Update with the correct bucket resource name
}