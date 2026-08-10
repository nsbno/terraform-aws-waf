module "waf" {
  source = "../../"

  name        = "example-cloudfront"
  description = "Protects the CloudFront distribution from unwanted actors"

  scope = "CLOUDFRONT"
  // CloudFront requires that the WAF is located in the same region as itself (us-east-1)
  region = "us-east-1"
}

resource "aws_cloudfront_distribution" "this" {
  enabled = true

  // CloudFront is unique in that the WAF is attached directly on the distribution,
  // instead of through a separate `aws_wafv2_web_acl_association` resource.
  web_acl_id = module.waf.acl_arn

  origin {
    domain_name = "example.com"
    origin_id   = "example"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "example"
    viewer_protocol_policy = "redirect-to-https"

    // AWS managed "CachingDisabled" policy - fine for this minimal example
    cache_policy_id = "4135ea2d-6df8-44a3-9ac2-3ba52c1cb69f"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
