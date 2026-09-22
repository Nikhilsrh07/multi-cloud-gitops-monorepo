variable "administrator_login_password" {
  description = "Administrator password for the Azure SQL server. Supply via a secure Terraform variable input."
  type        = string
  sensitive   = true
}
