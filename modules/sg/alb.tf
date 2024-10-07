# Security Group for EKS alb
resource "aws_security_group" "alb-ingress_sg" {
  name        = "${var.project_name}-eks-alb-sg-${var.env}"
  description = "Security group for EKS worker nodes"
  vpc_id      = data.aws_vpc.pw_vpc.id

  tags = {
    Name    = "${var.project_name}-eks-alb-sg-${var.env}"
    Env     = var.env
    Type    = var.type
    Project = var.project_name
  }

  dynamic "ingress" {
    for_each = var.eks_alb_ingress_rules
    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = ingress.value.cidr_blocks
      security_groups  = ingress.value.security_groups
      description      = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.eks_alb_egress_rules
    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = egress.value.cidr_blocks
      description      = egress.value.description
    }
  }
}