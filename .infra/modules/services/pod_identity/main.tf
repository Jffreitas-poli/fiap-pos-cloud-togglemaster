data "aws_iam_policy_document" "trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "service_role" {
  name               = "tc-${var.env}-${var.service_account}-role"
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json
}

resource "aws_iam_policy" "service_policy" {
  name        = "tc-${var.env}-${var.service_account}-policy"
  description = "Allows ${var.env} ${var.service_account} role to manage core AWS infrastructure"

  policy = var.policy_json
}

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role       = aws_iam_role.service_role.name
  policy_arn = aws_iam_policy.service_policy.arn
}

resource "aws_eks_pod_identity_association" "service_association" {
  cluster_name    = var.cluster_name
  namespace       = var.service_namespace
  service_account = var.service_account
  role_arn        = aws_iam_role.service_role.arn
}