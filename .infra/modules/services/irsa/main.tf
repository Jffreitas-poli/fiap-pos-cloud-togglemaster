data "aws_iam_policy_document" "trust_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:sub"
      values   = ["system:serviceaccount:${var.service_namespace}:${var.service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "service_role" {
  name               = "tc-${var.env}-${var.service_account}-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json
}

resource "aws_iam_policy" "service_policy" {
  count = length(var.policy_json)

  name        = "tc-${var.env}-${var.service_account}-policy"
  description = "Allows ${var.env} ${var.service_account} role to manage core AWS infrastructure"

  policy = var.policy_json[count.index]
}

resource "aws_iam_role_policy_attachment" "policy_attach_new" {
  count = length(var.policy_json)

  role       = aws_iam_role.service_role.name
  policy_arn = aws_iam_policy.service_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "policy_attach_existing" {
  count = length(var.policy_arn)

  role       = aws_iam_role.service_role.name
  policy_arn = var.policy_arn[count.index]
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = var.cluster_token
}

resource "kubernetes_annotations" "sa_arn_annotation" {
  count = length(var.have_annotations)

  annotations = {
    "eks.amazonaws.com/role-arn" = aws_iam_role.service_role.arn
  }
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = var.service_account
    namespace = var.service_namespace
  }

  force = true
}