resource "aws_iam_policy" "secrets_repo_encrypt_policy" {
  name = "${var.repo_name}-secrets-encrypt"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["codecommit:GitPull", "codecommit:GitPush"],
      "Effect": "Allow",
      "Sid": "gitpush",
      "Resource": ["${aws_codecommit_repository.secrets_repo.arn}"]
    },
    {
      "Action": ["kms:Encrypt", "kms:Decrypt"],
      "Effect": "Allow",
      "Sid": "decrypt",
      "Resource": ["${aws_kms_key.sops_key.arn}"]
    }
  ]
}
EOF
}

resource "aws_iam_role" "secrets_repo_encrypt_role" {
  name = "${var.repo_name}-secrets-encrypt"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::454929164628:user/yuvipanda"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "secrets_repo_encrypt_role_attach" {
  role       = aws_iam_role.secrets_repo_encrypt_role.name
  policy_arn = aws_iam_policy.secrets_repo_encrypt_policy.arn
}