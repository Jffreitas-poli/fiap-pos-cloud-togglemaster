module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 21.0"

  compute_config = {
    enabled = false
  }

  name               = "tc-${var.env}-eks"
  kubernetes_version = var.cluster_version

  create_iam_role = true

  #create_kms_key = false

  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API"

  endpoint_public_access  = true
  endpoint_private_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 5
      desired_size = 2
    }
  }

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    metrics-server = {}
  }

  tags = {
    Environment = var.env
    Terraform   = "true"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sgr_ingress_redis" {
  security_group_id = var.sg_redis

  referenced_security_group_id = module.eks.node_security_group_id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "sgr_ingress_rds" {
  security_group_id = var.sg_rds

  referenced_security_group_id = module.eks.node_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_iam_role" "eks_developer_role" {
  name = "tc-${var.env}-eks-developer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.eks_developer_arns
        }
      }
    ]
  })
}

resource "aws_eks_access_entry" "team_role" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.eks_developer_role.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "team_view" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  principal_arn = aws_eks_access_entry.team_role.principal_arn

  access_scope {
    type = "cluster"
  }
}

data "aws_eks_cluster_auth" "auth" {
  name = module.eks.cluster_name
}