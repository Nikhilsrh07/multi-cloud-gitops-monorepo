include {
  path = find_in_parent_folders("terragrunt.hcl")
}

inputs = {
  cloud = get_env("TG_CLOUD", "gcp")
}