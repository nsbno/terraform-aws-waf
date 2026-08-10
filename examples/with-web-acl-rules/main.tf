module "waf" {
  source = "../../"

  name        = "example-with-rules"
  description = "Protects the application with a couple of AWS managed rule groups"
}

resource "aws_wafv2_web_acl_rule" "amazon_ip_reputation_list" {
  name = "AmazonIpReputationList"

  // We recommend having some space between the priority of each rule,
  // Swapping position or doing large changes to the priority can result in conflicting priorities.
  // Not critical but annoying
  priority = 10

  web_acl_arn = module.waf.acl_arn

  override_action {
    // Always start with count {} before you start blocking.
    // Otherwise you risk blocking legitimate traffic
    none {}
  }

  statement {
    managed_rule_group_statement {
      name        = "AWSManagedRulesAmazonIpReputationList"
      vendor_name = "AWS"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "AmazonIpReputationList"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_rule" "rate_limit" {
  name        = "RateLimit"
  priority    = 20
  web_acl_arn = module.waf.acl_arn

  action {
    block {}
  }

  statement {
    rate_based_statement {
      // Blocks a single IP once it exceeds 1000 requests within a 5 minute window
      limit                 = 1000
      aggregate_key_type    = "IP"
      evaluation_window_sec = 300
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "RateLimit"
    sampled_requests_enabled   = true
  }
}
