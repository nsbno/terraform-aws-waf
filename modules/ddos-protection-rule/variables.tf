variable "acl_arn" {
  type = string
}

variable "name_prefix" {
  type        = string
  description = "Prefix to the rule names. Completely optional"
  nullable    = true
  default     = null
}

variable "region" {
  type     = string
  nullable = true
  default  = null
}

variable "priority" {
  type        = number
  description = "Where in the WAF-pipeline this should run. It is strongly recommended to run very early. Reserve the range [var.priority, 10), for any additional rules included in this module"
}

variable "block_action" {
  type = object({
    sensitivity = optional(string, "LOW")

    custom_response = optional(object({
      status   = optional(number)
      body_key = string
    }))
  })

  default = {
    sensitivity     = "LOW"
    custom_response = null
  }

  description = "Configure what happens to any block actions"
}

variable "challenge_action" {
  type = object({
    enabled     = optional(bool, true)
    sensitivity = optional(string, "HIGH")

    challenge_all_during_event = optional(bool, true)

    // Common static file extensions are excluded by default,
    // so you don't have to include them
    exempt_requests_regex = optional(list(string), [])
  })
  description = "Configure how the challenge action works. Enabled by default, and highly recommended"

  default = {
    enabled                    = true
    sensitivity                = "HIGH"
    challenge_all_during_event = true
    exempt_requests_regex      = []
  }
}

variable "automatic_rate_limit_during_attack" {
  type = object({
    enabled                   = bool
    threshold                 = optional(number, 50)
    evaluation_window_seconds = optional(number, 60) // 1 minute
    // Use if certain countries should be exempt from the rate-limit
    exempt_country_codes = optional(list(string), [])
  })
  description = "Additional protective mechanism for any requests that may elude the DDoS protection. Applies a strict rate-limit during DDoS attacks for requests without a Challenge-token"

  default = {
    enabled                   = true
    threshold                 = 50
    evaluation_window_seconds = 60
    exempt_country_codes      = []
  }
}