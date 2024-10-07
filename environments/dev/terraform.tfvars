aws_region           = "us-east-1"
assume_role_arn      = "arn:aws:iam::767397709508:role/pw-role-dev-crossaccount_infra_role"
env                  = "dev"

# EKS settings
eks_version      = "1.30"  # Replace with your desired EKS version
desired_size     = 2
max_size         = 3
min_size         = 2
instance_type    = "t2.medium"
disk_size        = 20
max_unavailable  = 1


################################################################################################
# Security Group Rules
################################################################################################


master_ingress_rules = [
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.11.0.0/19"]
    description = "Allow incoming HTTPS traffic from anywhere"
  },
  {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["10.11.0.0/19"]
    description = "Control plane to worker node communication"
  },
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.11.0.0/19"]
    description = "Control plane to worker node communication"
  },
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Pod to pod communication"
  },
  # {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.11.0.0/19"]
  #   description = "SSH access"
  # },
  {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["10.11.0.0/19"]
    description = "NodePort services"
  }
]

################################################################################################

master_egress_rules = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.11.0.0/19"]
    description = "Allow all outgoing traffic"
  }
]




################################################################################################
# alb security group
################################################################################################


# Ingress rules for EKS ALB security group
# eks_alb_ingress_rules = [
#   {
#     from_port        = 80
#     to_port          = 80
#     protocol         = "tcp"
#     cidr_blocks      = ["10.11.0.0/19"]
#     security_groups  = []  # You can specify security group IDs if needed
#     description      = "Allow HTTP traffic"
#   },
#   {
#     from_port        = 443
#     to_port          = 443
#     protocol         = "tcp"
#     cidr_blocks      = ["10.11.0.0/19"]
#     security_groups  = []  # You can specify security group IDs if needed
#     description      = "Allow HTTPS traffic"
#   }
# ]

# # Egress rules for EKS workers
# eks_alb_egress_rules = [
#   {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["10.11.0.0/19"]
#     description = "Allow all outbound traffic"
#   }
# ]
