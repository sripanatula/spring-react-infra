provider "aws" {
  region  = var.region
  profile = "default"
}

# Additional provider for ACM certificates (CloudFront requires us-east-1)
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = "default"
}
