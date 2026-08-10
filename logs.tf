
data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "this" {
  count = var.logs.enabled == true ? 1 : 0

  region = var.region
  // These logs must start with `aws-waf-logs-*`
  // https://docs.aws.amazon.com/waf/latest/developerguide/logging-cw-logs.html
  name              = "aws-waf-logs-${var.name}"
  retention_in_days = coalesce(var.logs.retention_in_days, 30)

  deletion_protection_enabled = coalesce(var.logs.delete_protection_enabled, false)
}

data "aws_iam_policy_document" "waf_logging" {
  version = "2012-10-17"

  statement {
    effect = "Allow"

    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }

    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.this[0].arn}:*"]

    condition {
      test     = "ArnEquals"
      values   = [aws_wafv2_web_acl.this.arn]
      variable = "aws:SourceArn"
    }

    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:SourceAccount"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "waf_logging" {
  count = var.logs.enabled == true ? 1 : 0

  region          = var.region
  policy_document = data.aws_iam_policy_document.waf_logging.json
  policy_name     = "aws-waf-logs-${var.name}"
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.logs.enabled == true ? 1 : 0

  region                  = var.region
  log_destination_configs = [aws_cloudwatch_log_group.this[0].arn]
  resource_arn            = aws_wafv2_web_acl.this.arn

  dynamic "logging_filter" {
    for_each = var.logs.exclude_allow_action_requests ? [1] : []
    content {
      default_behavior = "KEEP"

      filter {
        behavior    = "DROP"
        requirement = "MEETS_ANY"

        condition {
          action_condition {
            action = "ALLOW"
          }
        }
      }
    }
  }
}
