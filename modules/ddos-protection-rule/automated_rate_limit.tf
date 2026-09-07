locals {
  ddos_event_rate_limit_label = "needs-ddos-event-rate-limit"
}

// Identifies all requests without valid WAF-token AND outside Core countries (Norway, Sweden, Denmark)
// during a DDoS attack. Those request should automatically have a strict rate-limit
//
// Limitations in aws_wafv2_web_acl_rule prevents us from just using the scope_down_statement
// directly in aws_wafv2_web_acl_rule.ddos_event_rate_limit. When that is fixed in hashicorp/aws
// we can simplify this setup
resource "aws_wafv2_web_acl_rule" "match_ddos_event_rate_limit_targets" {
  count = var.automatic_rate_limit_during_attack.enabled ? 1 : 0

  region      = var.region
  name        = var.name_prefix != null ? "${var.name_prefix}-ddos-rate-limit-targets" : "ddos-rate-limit-targets"
  priority    = var.priority + 3
  web_acl_arn = var.acl_arn

  action {
    count {}
  }

  rule_label {
    name = local.ddos_event_rate_limit_label
  }

  statement {
    and_statement {
      statement {
        label_match_statement {
          scope = "LABEL"
          // Added by the anti_ddos rule above once AWS detects an ongoing DDoS event
          // against this resource. Every request gets this label while the event lasts.
          key = "awswaf:managed:aws:anti-ddos:event-detected"
        }
      }

      // Scope to only requests where the token is missing or been rejected.
      // That way requests with accepted tokens are excluded,
      // and endpoints that doesn't support challenge, such as static files
      // (they won't have any `awswaf:managed:token:*` labels)
      statement {
        or_statement {
          statement {
            label_match_statement {
              scope = "LABEL"
              key   = "awswaf:managed:token:absent"
            }
          }
          statement {
            label_match_statement {
              scope = "LABEL"
              key   = "awswaf:managed:token:rejected"
            }
          }
        }
      }

      dynamic "statement" {
        for_each = length(var.automatic_rate_limit_during_attack.exempt_country_codes) > 0 ? [1] : []
        content {
          not_statement {
            statement {
              geo_match_statement {
                country_codes = var.automatic_rate_limit_during_attack.exempt_country_codes
              }
            }
          }
        }
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "ddos-rate-limit-targets"
    sampled_requests_enabled   = false
  }
}

// Tighter rate-limit that only kicks in during a confirmed DDoS event, against the traffic
// labeled by match_ddos_event_rate_limit_targets above.
resource "aws_wafv2_web_acl_rule" "ddos_event_rate_limit" {
  count       = var.automatic_rate_limit_during_attack.enabled ? 1 : 0
  region      = var.region
  name        = var.name_prefix != null ? "${var.name_prefix}-ddos-rate-limit" : "ddos-rate-limit"
  priority    = aws_wafv2_web_acl_rule.match_ddos_event_rate_limit_targets[0].priority + 3
  web_acl_arn = var.acl_arn

  action {
    block {
      custom_response {
        response_code = 429 // 429 "Too many requests" is more descriptive than the default 403
      }
    }
  }

  statement {
    rate_based_statement {
      // 100 requests includes the requests that loads the page
      limit                 = var.automatic_rate_limit_during_attack.threshold
      aggregate_key_type    = "IP"
      evaluation_window_sec = var.automatic_rate_limit_during_attack.evaluation_window_seconds

      scope_down_statement {
        label_match_statement {
          scope = "LABEL"
          key   = local.ddos_event_rate_limit_label
        }
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ddos-rate-limit"
    sampled_requests_enabled   = true
  }
}
