// Minimal API Gateway example.
// A real setup should use https://github.com/nsbno/terraform-aws-rest-api
resource "aws_api_gateway_rest_api" "this" {
  name = "example"
}
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
}
resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = "prod"
}

module "waf" {
  source = "../../"

  name        = aws_api_gateway_rest_api.this.name
  description = "Protects the API Gateway from unwanted actors"
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_api_gateway_stage.this.arn
  web_acl_arn  = module.waf.acl_arn
}
