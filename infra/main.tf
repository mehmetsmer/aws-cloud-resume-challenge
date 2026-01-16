terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1" # Frankfurt
}

# DynamoDB Tablosu (v2) - Sayaç için
resource "aws_dynamodb_table" "resume_stats" {
  name           = "cloud-resume-stats-v2" 
  billing_mode   = "PAY_PER_REQUEST"       # On-demand 
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S" # String
  }
}

# DynamoDB Tablosu (v2) - IP Takibi için
resource "aws_dynamodb_table" "visitor_ips" {
  name           = "cloud-resume-ips-v2"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ip_address"

  attribute {
    name = "ip_address"
    type = "S"
  }
}

# 1. Lambda için IAM Rolü (Kimlik Kartı)
resource "aws_iam_role" "iam_for_lambda" {
  name = "cloud_resume_lambda_role_v2"

  # Sadece Lambda servisi için
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 2. Temel Lambda İzinleri (Log tutabilmesi için)
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 3. DynamoDB Erişim İzni (Özel Politika)
resource "aws_iam_policy" "dynamodb_access" {
  name        = "cloud_resume_dynamodb_policy_v2"
  description = "DynamoDB tablolarina erisim izni"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        # Sadece oluşturduğumuz v2 tablolarına izin ver (Güvenlik!)
        Resource = [
          aws_dynamodb_table.resume_stats.arn,
          aws_dynamodb_table.visitor_ips.arn
        ]
      }
    ]
  })
}

# 4. Bu özel politikayı Role yapıştır
resource "aws_iam_role_policy_attachment" "attach_dynamodb" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# 1. Python dosyasını ZIP haline getir
data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_file = "${path.module}/lambda/func.py"     # Kaynak dosya
  output_path = "${path.module}/lambda/func.zip"    # Çıktı zip dosyası
}

# 2. Lambda Fonksiyonunun Kendisi (v2)
resource "aws_lambda_function" "myfunc" {
  filename      = data.archive_file.zip_the_python_code.output_path
  function_name = "cloud-resume-func-v2"            # Yeni isim (v2)
  role          = aws_iam_role.iam_for_lambda.arn   # Yaptığımız Rol
  handler       = "func.lambda_handler"             # DosyaAdı.FonksiyonAdı
  runtime       = "python3.12"                      # Python Sürümü
  
  # Kod değişirse Lambda'yı güncellemesi için bu satır şart:
  source_code_hash = data.archive_file.zip_the_python_code.output_base64sha256
}

# 1. API Gateway (HTTP API)
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "cloud-resume-api-v2"
  protocol_type = "HTTP"

  # CORS ayarı
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
    max_age       = 300
  }
}

# 2. Stage (Otomatik Yayına Alma)
resource "aws_apigatewayv2_stage" "lambda_stage" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true
}

# 3. Integration (Lambda ile Bağlantı)
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  
  # API Gateway arka planda Lambda'yı her zaman POST ile çağırır, bu standarttır.
  integration_method = "POST" 
  integration_uri    = aws_lambda_function.myfunc.invoke_arn
  payload_format_version = "2.0"
}

# 4. Route (Yol Tarifi) - GET İsteği Gelince
resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# 5. İzin (Kapıdan gelene izin ver)
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.myfunc.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}

# 6. ÇIKTI (Linki Ekrana Yazdır)
output "api_url" {
  description = "API Linkin:"
  value       = aws_apigatewayv2_stage.lambda_stage.invoke_url
}