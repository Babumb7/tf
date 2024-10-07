locals {
  cluster-name = "${var.project_name}-eks-cluster-${var.env}"
  
  aws_account_id    = data.aws_caller_identity.current.account_id
  partition         = data.aws_partition.current.partition
  provider_url_oidc = substr("${aws_eks_cluster.eks.identity[0].oidc[0].issuer}",8,length("${aws_eks_cluster.eks.identity[0].oidc[0].issuer}")-1)

  karpenter_yaml = <<YAML
clusterName: "${aws_eks_cluster.eks.name}"
clusterEndpoint: "${aws_eks_cluster.eks.endpoint}"
hostNetwork: true

serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: "${aws_iam_role.karpenter.arn}"

aws:
  defaultInstanceProfile: "${var.project_name}-eks-worker-profile-${var.env}"

YAML

  karpenter_nodepool_yaml = <<YAML
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  disruption:
    consolidateAfter: 30s
    consolidationPolicy: WhenEmpty
    expireAfter: Never
  limits:
    cpu: "10"
  template:
    metadata:
        labels:
         clusterName: ${aws_eks_cluster.eks.name}
    spec:
      nodeClassRef:
        name: default
      requirements:
      - key: karpenter.k8s.aws/instance-category
        operator: In
        values: ["t"]
      - key: kubernetes.io/arch
        operator: In
        values: ["amd64"]

YAML

  karpenter_nodeclass_yaml = <<YAML
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2
  role: KarpenterRole-${aws_eks_cluster.eks.name}
  securityGroupSelectorTerms:
  - tags:
      aws:eks:cluster-name: ${aws_eks_cluster.eks.name}
  subnetSelectorTerms:
  - tags:
      Name: "pw-private-subnet-az*-${var.env}"
  tags:
    intent: apps
    managed-by: karpenter

YAML

  fluent_bit_yaml = <<YAML
input:
  parser: containerd
cloudWatchLogs:
  enabled: true
  #match: "kube.*"
  region: ${var.aws_region}
  logGroupName: ${aws_cloudwatch_log_group.fluent-bit.name}
  #logGroupTemplate: ${aws_cloudwatch_log_group.fluent-bit.name}
  #logStreamName: $kubernetes['container_name']
  #logStreamTemplate: $kubernetes['container_name']
  logStreamPrefix: "fluentbit."
  #logKey: log
kinesis:
  enabled: false
firehose:
  enabled: false
opensearch:
  enabled: true  
  host: "${aws_opensearch_domain.eks-opensearch.endpoint}"  
  port: 443
  index: eks-logs
  type: _doc
  logstash_format: true
  logstash_prefix: fluentbit
  tls: true
  aws_auth: true
  region: ${var.aws_region}
  match: "kube.*"  
rbac:
  create: false
service:
  extraParsers: |
    [PARSER]
        Name        containerd
        Format      regex
        Regex       ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<log>.*)$
        Time_Key    time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z
    [MULTILINE_PARSER]
        name multiline_logs
        type regex
        rule      "start_state"   "/^(\d+\-\d+\-\d+T\d+\:\d+\:\d+\.\d+)(.*)/"         "cont"
        rule      "cont"          "/^(?!(\d+\-\d+\-\d+T\d+\:\d+\:\d+\.\d+).*$).*/"   "cont"
additionalFilters: |
  [FILTER]
      Name                  multiline
      Match                 kube.*
      multiline.key_content log
      multiline.parser      multiline_logs
YAML
}
