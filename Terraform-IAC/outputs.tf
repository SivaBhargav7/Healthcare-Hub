output "api_gateway_url" {
  value = aws_apigatewayv2_api.healthcare_api.api_endpoint
}

output "rds_endpoint" {
  value = aws_db_instance.healthcare_rds.address
}

output "s3_website_url" {
  value = aws_s3_bucket.frontend_bucket.website_endpoint
}
