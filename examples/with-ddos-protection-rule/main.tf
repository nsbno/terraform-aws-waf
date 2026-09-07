locals {
  blocked_custom_response_key = "blocked-default"
}

module "waf" {
  source = "../../"

  name        = "example-with-ddos-protection"
  description = "Protects the application, with the built-in Anti-DDoS submodule handling volumetric attacks"

  scope = "CLOUDFRONT"

  custom_responses = {
    "${local.blocked_custom_response_key}" = {
      content      = "<h1>Blocked</h1><p>Your request was blocked by our firewall.</p>"
      content_type = "TEXT_HTML"
    }
  }
}

module "ddos_protection" {
  source = "../../modules/ddos-protection-rule"

  region   = module.waf.region
  acl_arn  = module.waf.acl_arn
  priority = 1 // Run this as early as possible in the rule evaluation

  // Optional. Prefixes every rule name created by this module, e.g.
  // "example-anti-ddos" instead of just "anti-ddos". Useful if you attach
  // more than one instance of this module to the same Web ACL.
  name_prefix = "example"

  block_action = {
    // Optional, defaults to "LOW"
    sensitivity = "LOW"

    // Optional, defaults to null (AWS's plain block response).
    // Make sure blocked DDoS requests also see our custom response body.
    custom_response = {
      status   = 403 // Optional, defaults to 403
      body_key = local.blocked_custom_response_key
    }
  }

  challenge_action = {
    // Optional, defaults to true. Set to false to rely on block_action only,
    // e.g. if your app can't handle the Challenge action at all.
    enabled = true

    sensitivity = "HIGH"

    // Optional, defaults to true. When true, ALL challengeable requests get
    // challenged during a confirmed event. Set to false if that's too
    // aggressive for some clients (e.g. older mobile app versions).
    challenge_all_during_event = true

    // Optional, defaults to []. Exclude paths/clients that can't gracefully
    // handle a silent browser challenge, e.g. server-to-server API calls
    // without the WAF JS SDK loaded.
    exempt_requests_regex = [
      "^\\/api\\/",
    ]
  }

  automatic_rate_limit_during_attack = {
    enabled = true

    // Optional, defaults to 50
    threshold = 100

    // Optional, defaults to 60 (1 minute)
    evaluation_window_seconds = 60

    // Optional, defaults to []. Requests without a valid WAF token, outside
    // these countries, get strictly rate-limited once AWS detects an
    // ongoing DDoS event.
    exempt_country_codes = ["NO", "SE", "DK"]
  }
}
