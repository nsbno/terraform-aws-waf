terraform-aws-waf
===

Protect your application with a fully-managed Web Application Firewall in AWS.

This module provides you with a usable baseline configuration to help you get started.
It doesn't include any Rules, because those are often very customized to
a specific application, therefore very difficult to make generic.

<!-- TOC -->
* [Usage](#usage)
* [Examples](#examples)
<!-- TOC -->

## Usage

Remember to check out the [variables](variables.tf) and [outputs](outputs.tf) to see all options.

```hcl
module "waf" {
  source = "github.com/nsbno/terraform-aws-waf?ref=x.y.z"

  name        = "my-waf-protected-application"
  description = "Protects the app from unwanted actors"

  logs = {
    enabled                       = true
    delete_protection_enabled     = var.environment == "prod"
    // Set to `true` to reduce the cost of logs in WAF.
    // Recommended to do, after you've gotten acquainted with 
    // the "normal" traffic towards your app and what you'd expect to block
    exclude_allow_action_requests = false
  }
}

// Attach your WAF to your application.
// You should attach this at the outermost layer of your app.
resource "aws_wafv2_web_acl_association" "load_balancer" {
  web_acl_arn  = module.waf.acl_arn
  
  // Example assumes you have an Application Load balancer.
  // Also works with CloudFront, API Gateway v1 and Cognito
  resource_arn = module.alb.arn
}
```

Use [aws_wafv2_web_acl_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_rule)
to add [Rules](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rules.html) to your WAF instance.

## Examples

* [Attached to CloudFront](examples/attached-to-cloudfront) - CloudFront is unique in that the WAF is attached directly on the distribution resource
* [Attached to API Gateway v1](examples/attached-to-api-gateway-v1) - Attached via `aws_wafv2_web_acl_association`, same as for an ALB or Cognito user pool
* [With Web ACL rules](examples/with-web-acl-rules) - Adding a couple of AWS managed rule groups as separate `aws_wafv2_web_acl_rule` resources

