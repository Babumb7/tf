variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "my-eks-project"
}

variable "env" {
  type        = string
  description = "Environment (e.g., dev, prod)"
  default     = "dev"
}

variable "type" {
  type        = string
  description = "Environment (e.g., dev, prod)"
  default     = "dev"
}

########################################################################################################
                # master_ingress_rules
########################################################################################################


variable "master_ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  description = "List of ingress rules for EKS master"
  default = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.11.0.0/19"]
      description = "Allow HTTPS from anywhere (for kubectl)"
    }
  ]
}


#######################################################################################################

variable "master_egress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  description = "List of egress rules for EKS master"
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["10.11.0.0/19"]
      description = "Allow all outbound traffic"
    }
  ]
}






# #########################################################################################################
#                 # worker_rules
# ########################################################################################################
# variable "workers_ingress_rules" {
#   type = list(object({
#     from_port       = number
#     to_port         = number
#     protocol        = string
#     cidr_blocks     = list(string)
#     security_groups = list(string)
#     description     = string
#   }))
#   description = "List of ingress rules for EKS workers"
#   default = [
#     {
#       from_port       = 10250
#       to_port         = 10250
#       protocol        = "tcp"
#       cidr_blocks     = []
#       security_groups = []  # This will be filled with the master SG ID
#       description     = "Allow kubelet API from master"
#     },
#     {
#       from_port       = 30000
#       to_port         = 32767
#       protocol        = "tcp"
#       cidr_blocks     = ["0.0.0.0/0"]
#       security_groups = []
#       description     = "Allow NodePort Services from anywhere"
#     }
#   ]
# }

# ########################################################################################################

# variable "workers_egress_rules" {
#   type = list(object({
#     from_port   = number
#     to_port     = number
#     protocol    = string
#     cidr_blocks = list(string)
#     description = string
#   }))
#   description = "List of egress rules for EKS workers"
#   default = [
#     {
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#       description = "Allow all outbound traffic"
#     }
#   ]
# }







#########################################################################################################
# eks_alb_rules
########################################################################################################

# variable "eks_alb_ingress_rules" {
#   description = "List of ingress rules for EKS ALB security group"
#   type = list(object({
#     from_port        = number
#     to_port          = number
#     protocol         = string
#     cidr_blocks      = list(string)
#     security_groups  = optional(list(string))
#     description      = string
#   }))
# }

# ########################################################################################################

# variable "eks_alb_egress_rules" {
#   description = "List of egress rules for EKS workers"
#   type = list(object({
#     from_port   = number
#     to_port     = number
#     protocol    = string
#     cidr_blocks = list(string)
#     description = string
#   }))
# }

#########################################################################################################
                # eks_alb_rules
########################################################################################################
variable "eks_alb_ingress_rules" {
  description = "List of ingress rules for EKS ALB security group"
  type = list(object({
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = list(string)
    security_groups  = optional(list(string))
    description      = string
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      security_groups = []
      description = "Allow HTTP traffic"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      security_groups = []
      description = "Allow HTTPS traffic"
    }
  ]
}
########################################################################################################

variable "eks_alb_egress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  description = "List of egress rules for EKS workers"
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}