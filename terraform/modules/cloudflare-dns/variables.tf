variable "zone_name" {
  description = "Cloudflare-managed DNS zone, for example nikhilsrh07.com."
  type        = string
}

variable "primary_cloud" {
  description = "Cloud whose VM IP serves www.<zone> — one DNS hostname for the site regardless of cloud."
  type        = string
  default     = "aws"

  validation {
    condition     = contains(["aws", "gcp", "azure"], var.primary_cloud)
    error_message = "primary_cloud must be one of: aws, gcp, azure."
  }
}

variable "cloud_ips" {
  description = "Map of cloud => VM public IP, discovered dynamically from Terraform outputs (no static IPs)."
  type        = map(string)
  default     = {}
}

variable "enable_cloud_redirects" {
  description = "301-redirect the per-cloud subdomains (aws./gcp./azure.) to https://www.<zone>."
  type        = bool
  default     = true
}

variable "proxied" {
  description = "Proxy web traffic through Cloudflare."
  type        = bool
  default     = true
}
