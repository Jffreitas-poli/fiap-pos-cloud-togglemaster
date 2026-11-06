# Keda
module "keda_identity" {
  source            = "./pod_identity"
  env               = var.env
  cluster_name      = var.cluster_name
  service_namespace = "keda"
  service_account   = "keda-operator"

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Cluster Secret Store
module "cluster_secret_store_identity" {
  source            = "./pod_identity"
  env               = var.env
  cluster_name      = var.cluster_name
  service_namespace = "external-secrets"
  service_account   = "external-secrets"

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Evaluation Service
module "evaluation_identity" {
  source            = "./pod_identity"
  env               = var.env
  cluster_name      = var.cluster_name
  service_namespace = "toggle"
  service_account   = "evaluation-service"

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "RedisAccess"
        Effect = "Allow"
        Action = [
          "elasticache:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Analytics Service
module "analytics_identity" {
  source            = "./pod_identity"
  env               = var.env
  cluster_name      = var.cluster_name
  service_namespace = "toggle"
  service_account   = "analytics-service"

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# EBS Driver
module "ebs_controller_irsa" {
  source                 = "./irsa"
  env                    = var.env
  cluster_endpoint       = var.cluster_endpoint
  cluster_ca_certificate = var.cluster_ca_certificate
  cluster_token          = var.cluster_token
  oidc_provider          = var.oidc_provider
  oidc_provider_arn      = var.oidc_provider_arn
  service_namespace      = "kube-system"
  service_account        = "ebs-csi-controller-sa"
  policy_json            = []
  policy_arn             = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
  have_annotations       = ["true"]
}

# Loki
module "loki_irsa" {
  source                 = "./irsa"
  env                    = var.env
  cluster_endpoint       = var.cluster_endpoint
  cluster_ca_certificate = var.cluster_ca_certificate
  cluster_token          = var.cluster_token
  oidc_provider          = var.oidc_provider
  oidc_provider_arn      = var.oidc_provider_arn
  service_namespace      = "loki"
  service_account        = "loki"
  policy_json = [jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LokiStorage"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.loki_chunk_bucket_name}",
          "arn:aws:s3:::${var.loki_chunk_bucket_name}/*",
          "arn:aws:s3:::${var.loki_ruler_bucket_name}",
          "arn:aws:s3:::${var.loki_ruler_bucket_name}/*"
        ]
      }
    ]
  })]
  policy_arn       = []
  have_annotations = []
}