terraform {
  backend "s3" {
    bucket       = "tc-prod-bucket-047719652987-us-east-1-an"
    key          = "tc-state"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}