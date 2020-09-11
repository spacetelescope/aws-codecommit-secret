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

resource "aws_s3_bucket" "sops-config" {
  bucket = var.sops_s3_bucket
  acl    = "private"
  tags = {
    Env =  "sandbox"
  }
}

resource "aws_s3_bucket_object" "sops-bucket" {
  bucket = var.sops_s3_bucket
  key    = var.sops_s3_key
  source = var.sops_s3_source
}
