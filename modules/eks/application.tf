resource "kubernetes_service_account" "customer" {
  automount_service_account_token = true
  metadata {
    name        = "customer"
    namespace   = var.customer_namespace_name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks-customer-role.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "eks-customer-role"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "aws_iam_role" "eks-customer-role" {
  name = "EksCustomerRole-${var.project_name}-eks-cluster-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow"
        "Principal": {
          "Service": "eks.amazonaws.com"
        }
        "Action": "sts:AssumeRole"
      },
      {
        Effect = "Allow",
        Principal = {
          Federated = "${aws_iam_openid_connect_provider.eks.arn}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:${var.customer_namespace_name}:customer",
            "${replace(aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "EksCustomerRole-${var.project_name}-eks-cluster-${var.env}"
    Track   = "devops"
    Project = var.project_name
    Env     = var.env
  }
}

resource "aws_iam_policy" "dynamodb-access-policy" {
  name = "${var.project_name}-eks-dynamodb-access-policy-${var.env}"
  description = "IAM policy for EKS to access DynamoDB"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws-dynamodb-access" {
  role       = aws_iam_role.eks-customer-role.name
  policy_arn = aws_iam_policy.dynamodb-access-policy.arn
}



