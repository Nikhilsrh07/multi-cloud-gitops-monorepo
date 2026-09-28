variable "db_password" {
  description = "Password for the AWS RDS database. Supply via a secure Terraform variable input."
  type        = string
  sensitive   = true
}
