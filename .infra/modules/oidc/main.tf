data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

resource "aws_iam_role" "github_actions" {
  name = "tc-${var.env}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "${var.git_repo_claim_prefix}:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "github_actions_policy" {
  name        = "tc-${var.env}-github-actions-policy"
  description = "Allows GitHub Actions role to manage core AWS infrastructure"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GitHubAccess"
        Effect = "Allow"
        Action = [
          "s3:*",
          "dynamodb:*",
          "sqs:*",
          "ecr:*",
          "elasticache:*",
          "eks:*",
          "rds:*",
          "ec2:*",
          "iam:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}
