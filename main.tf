locals {
  // WAF data protection doesn't ignore casing when matching header names,
  // so we need to include both the title-cased and lower-cased version.
  // For example: "Authorization" and "authorization"
  masked_headers_lowercase  = [for header in var.data_protection.mask_headers : lower(header)]
  masked_headers_title_case = [for header in local.masked_headers_lowercase : title(header)]
  masked_headers_all        = toset(concat(local.masked_headers_title_case, local.masked_headers_lowercase))

  // CloudFront-scoped WAFs must live in us-east-1
  region = var.scope == "CLOUDFRONT" ? "us-east-1" : var.region
}

resource "aws_wafv2_web_acl" "this" {
  region      = local.region
  name        = var.name
  description = var.description
  scope       = var.scope

  token_domains = var.token_domains

  // Add support for custom response bodies
  dynamic "custom_response_body" {
    for_each = var.custom_responses
    content {
      content      = custom_response_body.value.content
      content_type = custom_response_body.value.content_type
      key          = custom_response_body.key
    }
  }

  captcha_config {
    immunity_time_property {
      immunity_time = var.token_immunity_time.captcha_seconds
    }
  }
  challenge_config {
    immunity_time_property {
      immunity_time = var.token_immunity_time.challenge_seconds
    }
  }

  default_action {
    allow {}
  }

  data_protection_config {
    // Hashing versus substitution lets us mask the data,
    // and let us run analysis on those fields (count, count-distinct, etc)
    dynamic "data_protection" {
      for_each = length(local.masked_headers_all) > 0 ? [1] : []
      content {
        action = "HASH"

        field {
          field_type = "SINGLE_HEADER"
          field_keys = local.masked_headers_all
        }

        // Retains the raw-field if it matches on any rules that it triggers
        exclude_rate_based_details = true
        exclude_rule_match_details = true
      }
    }

    dynamic "data_protection" {
      for_each = length(var.data_protection.mask_cookies) > 0 ? [1] : []
      content {
        action = "HASH"

        field {
          field_type = "SINGLE_COOKIE"
          field_keys = var.data_protection.mask_cookies
        }

        exclude_rate_based_details = true
        exclude_rule_match_details = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.name
    sampled_requests_enabled   = true
  }

  lifecycle {
    ignore_changes = [rule]
  }
}
