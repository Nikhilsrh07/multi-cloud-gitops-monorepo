variable "zone_name" {
  description = "Cloudflare-managed DNS zone, for example nikhil-srh07.com."
  type        = string
}

variable "aws_origin" {
  description = "AWS ingress hostname."
  type        = string

  validation {
    condition     = trimspace(var.aws_origin) != ""
    error_message = "aws_origin must be a real AWS ingress hostname."
  }
}

variable "gcp_origin" {
  description = "GCP ingress hostname."
  type        = string

  validation {
    condition     = trimspace(var.gcp_origin) != ""
    error_message = "gcp_origin must be a real GCP ingress hostname."
  }
}

variable "azure_origin" {
  description = "Azure ingress hostname."
  type        = string

  validation {
    condition     = trimspace(var.azure_origin) != ""
    error_message = "azure_origin must be a real Azure ingress hostname."
  }
}

variable "primary_origin" {
  description = "Origin used by www until Cloudflare Load Balancing is enabled."
  type        = string

  validation {
    condition     = trimspace(var.primary_origin) != ""
    error_message = "primary_origin must be a real ingress hostname."
  }
}

variable "proxied" {
  description = "Proxy web traffic through Cloudflare."
  type        = bool
  default     = true
}