resource "aws_iam_service_linked_role" "opensearch-service-linked-role" {
  aws_service_name = "opensearchservice.amazonaws.com"
}

resource "aws_opensearch_domain" "eks-opensearch" {
  domain_name           = "${var.project_name}-eks-opensearch-${var.env}"
  engine_version        = "OpenSearch_2.15"    
 
  cluster_config {
    instance_type = "t3.medium.search"
    instance_count = var.opensearch_instance_count
    zone_awareness_enabled = true
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
    volume_type = "gp2"
  }

  vpc_options {
    subnet_ids         = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az2.id]
    security_group_ids = [var.eks_master_sg_id]
  }
  
  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  node_to_node_encryption {
    enabled = true
  }
  
  lifecycle {
    prevent_destroy = true
  }
  
  depends_on = [aws_iam_service_linked_role.opensearch-service-linked-role]
}

data "aws_iam_policy_document" "opensearch-access-policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["es:*"]

    resources = ["arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${aws_opensearch_domain.eks-opensearch.domain_name}/*"]
  }
}

# Attach the access policy to the OpenSearch domain
resource "aws_opensearch_domain_policy" "eks-opensearch-policy" {
  domain_name = aws_opensearch_domain.eks-opensearch.domain_name
  access_policies = data.aws_iam_policy_document.opensearch-access-policy.json
}

resource "aws_iam_role" "fluentbit-opensearch-role" {
  name = "fluentbit-role-${var.env}"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "eks.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_policy" "fluentbit-opensearch-policy" {
  name = "FluentBitOpenSearchPolicy-${var.env}"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "es:ESHttpPut",
          "es:ESHttpPost"
        ],
        "Resource" : "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${aws_opensearch_domain.eks-opensearch.domain_name}/*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "fluentbit-opensearch-role-attach" {
  role       = aws_iam_role.fluentbit-opensearch-role.name
  policy_arn = aws_iam_policy.fluentbit-opensearch-policy.arn
}





