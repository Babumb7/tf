###########################################################################################################
# Creating IAM role for ALB Load Balancer Controller
###########################################################################################################

# IAM role for ALB Load Balancer Controller
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${var.project_name}-eks-alb-controller-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.eks_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.eks_oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-eks-alb-controller-role-${var.env}"
    Track   = "devops"
    Project = var.project_name
    Env     = var.env
  }
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name = "${var.project_name}-eks-alb-controller-policy-${var.env}"
  policy = file("${path.module}/AWSLoadBalancerController.json")

  tags = {
    Name    = "${var.project_name}-eks-alb-controller-policy-${var.env}"
    Track   = "devops"
    Project = var.project_name
    Env     = var.env
  }
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

resource "aws_iam_role_policy" "load_balancer_controller_additional" {
  name = "${var.project_name}-eks-alb-controller-additional-policy-${var.env}"
  role = aws_iam_role.aws_load_balancer_controller.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags",
          "elasticloadbalancing:DeleteTargetGroup",
        ]
        Resource = "*"
      }
    ]
  })
}