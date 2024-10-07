###########################################################################################################
# Creating IAM role for Master Node
###########################################################################################################
# IAM role for Master Node
resource "aws_iam_role" "master" {
  name = "${var.project_name}-eks-master-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-eks-master-role-${var.env}"
    Track   = "devops"
    Project = var.project_name
    Env     = var.env
  }
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.master.name
}

############################################################################

# # IAM role for Fargate Pod Execution
# resource "aws_iam_role" "fargate_pod_execution_role" {
#   name = "${var.project_name}-eks-fargate-pod-execution-role-${var.env}"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "eks-fargate-pods.amazonaws.com"
#         }
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })

#   tags = {
#     Name    = "${var.project_name}-eks-fargate-pod-execution-role-${var.env}"
#     Track   = "devops"
#     Project = var.project_name
#     Env     = var.env
#   }
# }

# resource "aws_iam_role_policy_attachment" "fargate_pod_execution_role_policy_attachment" {
#   role       = aws_iam_role.fargate_pod_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
# }