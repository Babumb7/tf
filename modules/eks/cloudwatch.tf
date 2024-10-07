resource "kubernetes_namespace" "monitoring" {
  metadata {
    annotations = {
      name = "monitoring"
    }

    name = "monitoring"
  }
}

resource "kubernetes_service_account" "fluent-bit" {
  automount_service_account_token = true
  metadata {
    name        = "aws-for-fluent-bit"
    namespace   = kubernetes_namespace.monitoring.id
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.fluent-bit.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "aws-for-fluent-bit"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_service_account" "cloudwatch-metrics" {
  automount_service_account_token = true
  metadata {
    name        = "aws-cloudwatch-metrics"
    namespace   = kubernetes_namespace.monitoring.id
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.cloudwatch-metrics.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "aws-cloudwatch-metrics"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "fluent-bit" {
  chart      = "aws-for-fluent-bit"
  name       = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  version    = "0.1.32"

  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.fluent-bit.metadata[0].name
  }
  
  namespace = kubernetes_namespace.monitoring.id

  values = [local.fluent_bit_yaml]
}

resource "helm_release" "aws-cloudwatch-metrics" {
  chart      = "aws-cloudwatch-metrics"
  name       = "aws-cloudwatch-metrics"
  repository = "https://aws.github.io/eks-charts"

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks.name
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.cloudwatch-metrics.metadata[0].name
  }

  namespace = kubernetes_namespace.monitoring.id

}

resource "aws_iam_policy" "aws_cloudwatch" {
  name        = "AWSCloudwatchIAMPolicy"
  path        = "/"
  description = "policy for aws cloudwatch"
  policy      = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "firehose:PutRecordBatch"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "logs:PutLogEvents",
          "Resource" : "arn:aws:logs:*:*:log-group:*:*:*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogStream",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents"
          ],
          "Resource" : "arn:aws:logs:*:*:log-group:*"
        },
        {
          "Effect" : "Allow",
          "Action" : "logs:CreateLogGroup",
          "Resource" : "*"
        }
      ]
    })

}

resource "aws_iam_role" "fluent-bit" {
  name = "AmazonEKSFluentbitRole-${var.env}"
  path = "/"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Federated" : "${aws_iam_openid_connect_provider.eks.arn}"
          },
          "Action" : "sts:AssumeRoleWithWebIdentity",
          "Condition" : {
            "StringEquals" : {
              "${replace(aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:${kubernetes_namespace.monitoring.id}:aws-for-fluent-bit",
              "${replace(aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:aud" : "sts.amazonaws.com"
            }
          }
        }
      ]
    })

}

resource "aws_iam_role" "cloudwatch-metrics" {
  name = "AmazonEKSCloudwatchMetricsRole-${var.env}"
  path = "/"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Federated" : "${aws_iam_openid_connect_provider.eks.arn}"
          },
          "Action" : "sts:AssumeRoleWithWebIdentity",
          "Condition" : {
            "StringEquals" : {
              "${replace(aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:${kubernetes_namespace.monitoring.id}:aws-cloudwatch-metrics",
              "${replace(aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:aud" : "sts.amazonaws.com"
            }
          }
        }
      ]
    })

}

resource "aws_iam_role_policy_attachment" "aws-fluent-bit" {
  role       = aws_iam_role.fluent-bit.name
  policy_arn = aws_iam_policy.aws_cloudwatch.arn
}

data "aws_iam_policy" "cloudwatch-agent-policy" {
  name = "CloudWatchAgentServerPolicy"
}

resource "aws_iam_policy" "cloudwatch-agent-custom-policy" {
  name        = "AWSCloudwatchMetricsIAMPolicy"
  path        = "/"
  description = "Custom policy for aws cloudwatch metrics ec2 tags"
  policy      = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : ["ec2:DescribeVolumes", "ec2:DescribeTags"],
          "Resource" : "*",
          "Effect" : "Allow"
        }
      ]
    })

}

resource "aws_iam_role_policy_attachment" "aws-cloudwatch-metrics-CloudWatchAgentServerPolicy" {
  role       = aws_iam_role.cloudwatch-metrics.name
  policy_arn = data.aws_iam_policy.cloudwatch-agent-policy.arn
}

resource "aws_iam_role_policy_attachment" "aws-cloudwatch-metrics-AWSCloudwatchMetricsIAMPolicy" {
  role       = aws_iam_role.cloudwatch-metrics.name
  policy_arn = aws_iam_policy.cloudwatch-agent-custom-policy.arn
}

resource "aws_cloudwatch_log_group" "fluent-bit" {
  name              = "/aws/eks/${aws_eks_cluster.eks.name}/fluentbit"
  retention_in_days = 7
  
  kms_key_id  = data.aws_kms_key.cloudwatch-log-group.arn

  tags = {
    Name    = "${var.project_name}-eks-cluster-logs-${var.env}"
    Track   = "devops"
    Project = var.project_name
    Env     = var.env
  }
}