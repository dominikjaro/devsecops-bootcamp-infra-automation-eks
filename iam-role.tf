resource "aws_iam_role" "external-admin" {
  name = "external-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { AWS = var.user_for_admin_role }
    }]
  })
}
resource "aws_iam_role" "external-developer" {
  name = "external-developer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { AWS = var.user_for_dev_role }
    }]
  })
}
resource "aws_iam_role_policy" "external_admin_eks_describe" {
  name = "eks-describe-access"
  role = aws_iam_role.external-admin.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["eks:DescribeCluster", "eks:ListClusters"]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "external_developer_eks_describe" {
  name = "eks-describe-access"
  role = aws_iam_role.external-developer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["eks:DescribeCluster", "eks:ListClusters"]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

### Role to access AWS Secret Manager ###
resource "aws_iam_role" "externalsecrets_role" {
  name = "externalsecrets-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Sid       = ""
      Effect    = "Allow"
      Federated = module.eks.oidc_provider_arn
    }]
  })
}
resource "aws_iam_role_policy" "external_secrets_policy" {
  name = "externalsecrets-sa-role-policy"
  role = aws_iam_role.externalsecrets_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "secretsmanager:GetRandomPassword",
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecretVersionIds",
        "secretsmanager:ListSecrets",
        "secretsmanager:BatchGetSecretValue"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}
