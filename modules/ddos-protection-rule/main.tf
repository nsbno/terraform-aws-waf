locals {
  anti_ddos_rule_name = var.name_prefix != null ? "${var.name_prefix}-anti-ddos" : "anti-ddos"
}

resource "aws_wafv2_web_acl_rule" "anti_ddos" {
  region      = var.region
  name        = local.anti_ddos_rule_name
  priority    = var.priority
  web_acl_arn = var.acl_arn

  override_action {
    none {}
  }

  statement {
    managed_rule_group_statement {
      name        = "AWSManagedRulesAntiDDoSRuleSet"
      vendor_name = "AWS"

      managed_rule_group_configs {
        aws_managed_rules_anti_ddos_rule_set {
          sensitivity_to_block = var.block_action.sensitivity

          client_side_action_config {
            challenge {
              usage_of_action = var.challenge_action.enabled ? "ENABLED" : "DISABLED"
              sensitivity     = var.challenge_action.sensitivity

              dynamic "exempt_uri_regular_expression" {
                for_each = var.challenge_action.exempt_requests_regex
                content {
                  regex_string = exempt_uri_regular_expression.value
                }
              }
            }
          }
        }
      }

      rule_action_override {
        name = "ChallengeAllDuringEvent"
        action_to_use {
          dynamic "challenge" {
            // Always default to challenge unless EXPLICITLY disabled
            for_each = var.challenge_action.challenge_all_during_event != false ? [1] : []
            content {}
          }

          dynamic "count" {
            for_each = var.challenge_action.challenge_all_during_event == false ? [1] : []
            content {}
          }
        }
      }

      rule_action_override {
        name = "DDoSRequests"
        action_to_use {
          block {
            dynamic "custom_response" {
              for_each = var.block_action.custom_response != null ? [1] : []
              content {
                response_code            = coalesce(var.block_action.custom_response.status, 403)
                custom_response_body_key = var.block_action.custom_response.body_key
              }
            }
          }
        }
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = local.anti_ddos_rule_name
    sampled_requests_enabled   = true
  }
}

