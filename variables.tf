variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "scope" {
  type    = string
  default = "REGIONAL"

  validation {
    condition     = var.scope == "REGIONAL" || var.scope == "CLOUDFRONT"
    error_message = "Scope must be either: REGIONAL or CLOUDFRONT"
  }

  validation {
    condition     = var.scope != "CLOUDFRONT" || var.region != "us-east-1"
    error_message = "When scope is CLOUDFRONT, the region must be us-east-1"
  }
}

variable "logs" {
  type = object({
    enabled                   = optional(bool)
    delete_protection_enabled = optional(bool)
    retention_in_days         = optional(number)
    // Requests with allow actions typically attributes to 99% of the log entries,
    // but the non-allowed actions are the interesting ones.
    // Activate if you want to reduce the CloudWatch Logs cost, but keep the important log entries
    exclude_allow_action_requests = optional(bool)
  })

  default = {
    enabled                       = true
    delete_protection_enabled     = false
    exclude_allow_action_requests = true
    retention_in_days             = null
  }
}

variable "region" {
  type     = string
  nullable = true
  default  = null
}

variable "token_immunity_time" {
  type = object({
    captcha_seconds   = number
    challenge_seconds = number
  })
  default = {
    // For testing 300s (5m) is a good number (and the lowest allowed).
    // In production we should use something way longer
    captcha_seconds   = 300
    challenge_seconds = 300
  }
}

variable "token_domains" {
  type    = set(string)
  default = []
}