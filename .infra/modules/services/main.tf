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