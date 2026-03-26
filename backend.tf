terraform {
  backend "s3" {
    bucket = "ecs-sanbox-vrv" # Create this first
    key    = "ecs-sandbox/terraform.tfstate"
    region = "us-east-1"
    #dynamodb_table = "terraform-locks"              # Create this first
    use_lockfile = "true" # Create this first
    encrypt      = true
  }
}

