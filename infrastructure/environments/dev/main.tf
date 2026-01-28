module "vpc" {
  source = "../../modules/vpc"

  name            = "${var.environment}-vpc"
  cidr_block      = var.vpc_cidr
  azs             = ["${var.region}a", "${var.region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  # Enable Single NAT Gateway to save costs in Dev
  enable_nat_gateway = true
  single_nat_gateway = true

  # Essential for EKS auto-discovery
  cluster_name = var.cluster_name
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  node_groups = {
    main = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = ["t3.medium"] # Cost effective for dev
    }
  }
}
