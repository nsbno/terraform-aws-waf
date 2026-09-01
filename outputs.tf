output "acl_id" {
  value = aws_wafv2_web_acl.this.id
}

output "acl_arn" {
  value = aws_wafv2_web_acl.this.arn
}

output "region" {
  value = aws_wafv2_web_acl.this.region
}