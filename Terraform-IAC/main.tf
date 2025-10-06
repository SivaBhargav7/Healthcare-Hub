provider "aws" {
  region = "ap-southeast-2"
}

# --- VPC ---
resource "aws_vpc" "healthcare_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "healthcare-vpc"
  }
}

# --- Subnets ---
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.healthcare_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-2a"

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.healthcare_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "private-subnet"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "healthcare_igw" {
  vpc_id = aws_vpc.healthcare_vpc.id

  tags = {
    Name = "healthcare-igw"
  }
}

# --- Route Table ---
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.healthcare_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.healthcare_igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# --- Security Groups ---
resource "aws_security_group" "lambda_sg" {
  vpc_id = aws_vpc.healthcare_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lambda-sg"
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.healthcare_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

# --- RDS Database ---
resource "aws_db_subnet_group" "healthcare_db_subnet_group" {
  name       = "healthcare-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet.id]
}

resource "aws_db_instance" "healthcare_rds" {
  identifier              = "healthcare-db"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  name                    = "healthcare_app"
  username                = "Sivabhargav"
  password                = "sivabhargav1437"
  db_subnet_group_name    = aws_db_subnet_group.healthcare_db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  deletion_protection     = false

  tags = {
    Name = "healthcare-rds"
  }
}

# --- IAM Role for Lambda ---
resource "aws_iam_role" "lambda_role" {
  name = "healthcare-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- Lambda Function ---
resource "aws_lambda_function" "appointment_lambda" {
  function_name = "healthcare-appointment-handler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DB_HOST     = aws_db_instance.healthcare_rds.address
      DB_USER     = "Sivabhargav"
      DB_PASSWORD = "sivabhargav1437"
      DB_NAME     = "healthcare_app"
    }
  }
}

# --- API Gateway ---
resource "aws_apigatewayv2_api" "healthcare_api" {
  name          = "HealthcareAPI"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.healthcare_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.appointment_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "healthcare_route" {
  api_id    = aws_apigatewayv2_api.healthcare_api.id
  route_key = "POST /appointments"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.appointment_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.healthcare_api.execution_arn}/*"
}

# --- S3 Frontend Hosting ---
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "healthcare-frontend-${random_id.bucket_suffix.hex}"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name = "healthcare-frontend"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}
