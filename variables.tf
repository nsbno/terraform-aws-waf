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
    // Region is set to us-east-1 for CLOUDFRONT scope unless overridden with something else.
    condition     = var.scope != "CLOUDFRONT" || var.region == null || var.region == "us-east-1"
    error_message = "When scope is CLOUDFRONT, the region must be us-east-1 (or left unset)"
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

variable "custom_responses" {
  description = "Custom response bodies, named by the key rules reference via `custom_response_body_key`."
  type = map(object({
    content      = string
    content_type = string
  }))
  default = {}
}

variable "data_protection" {
  description = "Headers/cookies to hash in WAF logs before storage, so sensitive values aren't stored in plaintext."
  type = object({
    mask_headers = optional(list(string), ["Authorization"])
    // List the sensitive cookies your application actually sets, e.g. session/auth cookies.
    mask_cookies = optional(list(string), [])
  })
  default = {}
}
