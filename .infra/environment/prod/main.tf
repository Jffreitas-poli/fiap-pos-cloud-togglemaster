# Provider
provider "aws" {
  region = "us-east-1"
}

# VPC
module "vpc" {
  source          = "../../modules/vpc"
  env             = var.env
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

# RDS
module "sng" {
  source             = "../../modules/sng"
  env                = var.env
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
}

module "rds" {
  count = length(var.rds_names)

  source  = "../../modules/rds"
  env     = var.env
  db_name = var.rds_names[count.index]
  db_user = "postgres"
  db_pass = var.rds_passs[count.index]
  sng_id  = module.sng.sng_id
  sg_id   = module.sng.sg_id
}

# Redis
module "redis" {
  source             = "../../modules/redis"
  env                = var.env
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
}

# SQS
module "sqs" {
  source = "../../modules/sqs"
  env    = var.env
}

# Dynamo
module "dynamo" {
  source = "../../modules/dynamo"
  env    = var.env
}

# EKS
module "eks" {
  source             = "../../modules/eks"
  env                = var.env
  cluster_version    = var.cluster_version
  subnet_ids         = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  vpc_id             = module.vpc.vpc_id
  eks_developer_arns = var.eks_developer_arns
  sg_redis           = module.redis.sg_id
  sg_rds             = module.sng.sg_id
}

module "argo" {
  source                             = "../../modules/argo"
  cluster_name                       = module.eks.cluster_name
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_version                    = module.eks.cluster_version
  cluster_token                      = module.eks.cluster_token
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  oidc_provider_arn                  = module.eks.oidc_provider_arn

  service_names = [ "auth", "flag", "targeting", "evaluation", "analytics" ]
}

module "services" {
  source       = "../../modules/services"
  env          = var.env
  cluster_name = module.eks.cluster_name
}

#Github OIDC
module "oidc" {
  source                = "../../modules/oidc"
  env                   = var.env
  git_repo_claim_prefix = var.git_repo_claim_prefix
}

# ECR
module "ecr" {
  count = length(var.ecr_names)

  source = "../../modules/ecr"
  env    = var.env
  name   = var.ecr_names[count.index]
}