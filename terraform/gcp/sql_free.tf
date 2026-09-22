resource "google_sql_database_instance" "free_instance" {
  name             = "nikhilsrh07-gcp-db"
  database_version = "POSTGRES_15"
  region           = "us-central1"
  settings {
    tier              = "db-f1-micro" # Shared-core micro free sandbox
    activation_policy = "ALWAYS"
    availability_type = "ZONAL"
  }
  deletion_protection = false
}
