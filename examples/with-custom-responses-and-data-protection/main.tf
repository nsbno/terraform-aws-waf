module "waf" {
  source = "../../"

  name        = "example-with-custom-responses"
  description = "Protects the application, with a branded block page and extra log masking"

  // Shows your own page instead of AWS's plain block response when a rule
  // blocks a request. Referenced from a rule's `custom_response_body_key`.
  custom_responses = {
    "blocked-default" = {
      content      = file("${path.module}/blocked.html")
      content_type = "TEXT_HTML"
    }
  }

  // Headers and cookies are logged in plaintext by default, which is a
  // problem for things like Authorization tokens or session cookies.
  // This hashes the configured fields before they're written to logs.
  data_protection = {
    // Optional, defaults to ["Authorization"] if omitted
    mask_headers = ["Authorization"]
    // No default, cookie names are application-specific
    mask_cookies = ["my-session-cookie"]
  }
}
