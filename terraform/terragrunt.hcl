remote_state {
  backend = "s3"
  config = {
    bucket         = "nikhilsrh07-global-tf-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
