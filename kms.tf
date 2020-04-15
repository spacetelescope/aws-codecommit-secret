resource "aws_kms_key" "sops_key" {
  description             = "Encryption key for hubploy secrets in CodeCommit repo ${var.cluster_name}-secrets"
}

resource "local_file" "sops-config" {
  filename = ".sops.yaml"
  content = <<EOF
creation_rules:
  - path_regex: deployments/(.*)/secrets/(.*)$
    kms: "${aws_kms_key.sops_key.arn}"
EOF
}
