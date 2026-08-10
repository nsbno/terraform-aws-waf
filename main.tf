resource "aws_wafv2_web_acl" "this" {
  region      = var.region
  name        = var.name
  description = var.description
  scope       = var.scope

  token_domains = var.token_domains

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
    data_protection {
      // Hashing versus substitution lets to mask the data,
      // and let us run analysis on those fields (count, count-distinct, etc)
      action = "HASH"

      field {
        field_type = "SINGLE_HEADER"
        // Apparently not case-insensitive matching...
        field_keys = ["Authorization", "authorization"]
      }

      // Retains the raw-field if it matches on any rules that it triggers
      exclude_rate_based_details = true
      exclude_rule_match_details = true
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