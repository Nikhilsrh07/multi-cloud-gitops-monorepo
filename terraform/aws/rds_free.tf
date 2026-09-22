resource "aws_db_instance" "free_db" {
  allocated_storage     = 20
  max_allocated_storage = 20
  engine                = "postgres"
  instance_class        = "db.t3.micro" # AWS Free Tier Eligible
  db_name               = "nikhildb"
  username              = "nikhilsrh07"
  password              = var.db_password
  skip_final_snapshot   = true
  multi_az              = false
}
