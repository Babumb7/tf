# EKS Node Group Resource
resource "aws_eks_node_group" "node-grp" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.project_name}-eks-node-group-${var.env}"
  node_role_arn   = var.worker_role_arn
  subnet_ids      = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az2.id]
  capacity_type   = var.capacity_type
  disk_size       = var.disk_size
  instance_types  = [var.instance_type]

  # remote_access {
  #   ec2_ssh_key               = var.ec2_ssh_key_name
  #   source_security_group_ids = [var.bastion_sg_id]
  # }

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable = var.max_unavailable
  }

  # labels = {
  #   "eks.amazonaws.com/capacityType" = var.capacity_type
  # }

  # depends_on = [
  #   aws_iam_role_policy_attachment.eks_AmazonEKSWorkerNodePolicy,
  #   aws_iam_role_policy_attachment.eks_AmazonEKS_CNI_Policy,
  #   aws_iam_role_policy_attachment.eks_AmazonEC2ContainerRegistryReadOnly,
  # ]

  tags = {
    Name    = "${var.project_name}-node-group-${var.env}"
    Track   = "devops"
    Project = var.project_name
    Env     = var.env
    
    "karpenter.sh/discovery/${aws_eks_cluster.eks.name}" = aws_eks_cluster.eks.name
    "karpenter.k8s.aws/cluster"                          = var.env
  }
}














################################################################################################


# # EKS Node Group
# resource "aws_eks_node_group" "main" {
#   cluster_name    = aws_eks_cluster.eks.name
#   node_group_name = "${var.project_name}-node-group-${var.env}"
#   node_role_arn   = var.worker_role_arn
#   subnet_ids      = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az2.id]

#   scaling_config {
#     desired_size = var.desired_size
#     max_size     = var.max_size
#     min_size     = var.min_size
#   }

#   update_config {
#     max_unavailable = 1
#   }

#   launch_template {
#     id      = aws_launch_template.eks_nodes.id
#     version = aws_launch_template.eks_nodes.latest_version
#   }
#   # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
#   # depends_on = [
#   #   # aws_iam_role_policy_attachment.eks_AmazonEKSWorkerNodePolicy,
#   #   aws_iam_role_policy_attachment.eks_AmazonEKS_CNI_Policy,
#   #   aws_iam_role_policy_attachment.eks_AmazonEC2ContainerRegistryReadOnly,
#   # ]

#    tags = {
#     Name    = "${var.project_name}-node-group-${var.env}"
#     Track   = "devops"
#     Project = var.project_name
#     Env     = var.env
#   }
# }
# # Launch Template for EKS Nodes
# resource "aws_launch_template" "eks_nodes" {
#   name = "${var.project_name}-eks-node-template-${var.env}"

#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       volume_size = var.node_volume_size
#       volume_type = "gp3"
#       encrypted   = false
#       # kms_key_id  = aws_kms_key.ebs.arn
#     }
#   }

#   instance_type = var.instance_type

#   metadata_options {
#     http_endpoint               = "enabled"
#     http_tokens                 = "required"
#     http_put_response_hop_limit = 1
#   }

#   monitoring {
#     enabled = true
#   }

#   network_interfaces {
#     associate_public_ip_address = false
#     security_groups             = [var.eks_workers_sg_id]
#   }

#   image_id = var.eks_ami_id

#   tag_specifications {
#     resource_type = "instance"
#     tags = {
#       Name    = "${var.project_name}-eks-node-{LAUNCH_INDEX}-${var.env}"
#       Track   = "devops"
#       Project = var.project_name
#       Env     = var.env
#     }
#   }

# #   user_data = base64encode(<<-EOF
# #   #!/bin/bash
# #   set -o xtrace
# #   /etc/eks/bootstrap.sh ${aws_eks_cluster.eks.name} \
# #     --b64-cluster-ca ${aws_eks_cluster.eks.certificate_authority[0].data} \
# #     --apiserver-endpoint ${aws_eks_cluster.eks.endpoint} \
# #     --dns-cluster-ip 10.100.0.10 \
# #     --kubelet-extra-args "--node-labels=eks.amazonaws.com/nodegroup-image=${var.eks_ami_id},eks.amazonaws.com/capacityType=ON_DEMAND"
  
# #   INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
# #   LAUNCH_INDEX=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[].Instances[].LaunchIndex' --output text)
# #   LAUNCH_INDEX=$((LAUNCH_INDEX + 1))
# #   INSTANCE_NAME="${var.project_name}-eks-node-$LAUNCH_INDEX-${var.env}"
# #   aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$INSTANCE_NAME
# #   hostnamectl set-hostname $INSTANCE_NAME
# #   echo "127.0.0.1 $INSTANCE_NAME" >> /etc/hosts
# # EOF
# # )

# user_data = base64encode(<<-EOF
#     #!/bin/bash
#     set -o xtrace
#     /etc/eks/bootstrap.sh ${aws_eks_cluster.eks.name} \
#       --b64-cluster-ca ${aws_eks_cluster.eks.certificate_authority[0].data} \
#       --apiserver-endpoint ${aws_eks_cluster.eks.endpoint} \
#       --dns-cluster-ip 10.100.0.10 \
#       --kubelet-extra-args "--node-labels=eks.amazonaws.com/nodegroup-image=${var.eks_ami_id},eks.amazonaws.com/capacityType=ON_DEMAND" \
#       --container-runtime containerd \
#       2>&1 | tee /var/log/eks-bootstrap.log

#     # Check if bootstrap was successful
#     if [ $? -eq 0 ]; then
#       echo "EKS bootstrap successful" | tee -a /var/log/eks-bootstrap.log
#     else
#       echo "EKS bootstrap failed" | tee -a /var/log/eks-bootstrap.log
#     fi
#   EOF
#   )

#   # iam_instance_profile {
#   #   name = aws_iam_instance_profile.eks_node_instance_profile.name
#   # }

#   tags = {
#     Name    = "${var.project_name}-eks-node-template-${var.env}"
#     Track   = "devops"
#     Project = var.project_name
#     Env     = var.env
#   }
# }



# # IAM Instance Profile for EKS Nodes
# # resource "aws_iam_instance_profile" "eks_node_instance_profile" {
# #   name = "${var.project_name}-eks-node-instance-profile"
# #   role = var.worker_role_arn
# # }

# resource "aws_iam_instance_profile" "eks_node_instance_profile" {
#   name = "${var.project_name}-eks-node-instance-profile-${var.env}"
#   role = var.worker_role_name

#   tags = {
#     Name    = "${var.project_name}-eks-node-instance-profile-${var.env}"
#     Project = var.project_name
#     Env     = var.env
#   }
# }

# #####################################  KMS Key  ################################################

# # KMS Key for EBS encryption
# # KMS Key for EBS encryption
# resource "aws_kms_key" "ebs" {
#   description             = "KMS key for EBS encryption"
#   deletion_window_in_days = 7
#   enable_key_rotation     = true
#   is_enabled              = true

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "Enable IAM User Permissions"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         }
#         Action   = "kms:*"
#         Resource = "*"
#       },
#       {
#         Sid    = "Allow use of the key"
#         Effect = "Allow"
#         Principal = {
#           AWS = var.worker_role_arn
#         }
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ]
#         Resource = "*"
#       },
#       {
#         Sid    = "Allow use of the key for EKS"
#         Effect = "Allow"
#         Principal = {
#           Service = "eks.amazonaws.com"
#         }
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ]
#         Resource = "*"
#       },
#       {
#         Sid    = "Allow attachment of persistent resources for EC2"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#         Action = [
#           "kms:CreateGrant",
#           "kms:ListGrants",
#           "kms:RevokeGrant"
#         ]
#         Resource = "*"
#         Condition = {
#           Bool = {
#             "kms:GrantIsForAWSResource": "true"
#           }
#         }
#       }
#     ]
#   })

#   tags = {
#     Name    = "${var.project_name}-ebs-kms-key-${var.env}"
#     Track   = "devops"
#     Project = var.project_name
#     Env     = var.env
#   }
# }

# # # EKS Node Group
# # resource "aws_eks_node_group" "main" {
# #   cluster_name    = aws_eks_cluster.eks.name
# #   node_group_name = "${var.project_name}-node-group"
# #   node_role_arn   = aws_iam_role.eks_nodes.arn
# #   subnet_ids      = [var.private_subnet_az1_id, var.private_subnet_az2_id]

# #   ami_type       = "CUSTOM"
# #   release_version = var.ami_release_version
# #   instance_types = ["t3.medium"]  # Adjust as needed

# #   scaling_config {
# #     desired_size = 2
# #     max_size     = 5
# #     min_size     = 1
# #   }

# #   update_config {
# #     max_unavailable = 1
# #   }

# # #   labels = {
# # #     Environment = var.env
# # #   }

# #   # Use custom launch template
# # #   launch_template {
# # #     name    = aws_launch_template.eks_nodes.name
# # #     version = aws_launch_template.eks_nodes.latest_version
# # #   }

# #   # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
# #   depends_on = [
# #     aws_iam_role_policy_attachment.eks_AmazonEKSWorkerNodePolicy,
# #     aws_iam_role_policy_attachment.eks_AmazonEKS_CNI_Policy,
# #     aws_iam_role_policy_attachment.eks_AmazonEC2ContainerRegistryReadOnly,
# #   ]

# #   tags = {
# #     Name = "${var.project_name}-node-group"
# #     Env  = var.env
# #     Type = var.type
# #   }
# # }





#########################################################################


########################################################################################################



#