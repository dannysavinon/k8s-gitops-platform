provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "k8s-gitops-platform"
      ManagedBy   = "Terraform"
    }
  }
}
