resource "aws_kms_key" "sops_key" {
  description             = "Encryption key for hubploy secrets in CodeCommit repo ${var.repo_name}-secrets"
}

resource "local_file" "sops-config" {
  filename = ".sops.yaml"
  content = <<EOF
creation_rules:
  - path_regex: .*
    kms: "${aws_kms_key.sops_key.arn}"
EOF
}

# upload .sops.yaml to S3; it will be downloaded later in the process
# ...
