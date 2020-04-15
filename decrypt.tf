resource "aws_iam_policy" "secrets_repo_decrypt_policy" {
  name = "${var.cluster_name}-secrets-decrypt"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["codecommit:GitPull"],
      "Effect": "Allow",
      "Sid": "gitpull",
      "Resource": ["${aws_codecommit_repository.secrets_repo.arn}"]
    },
    {
      "Action": ["kms:Decrypt"],
      "Effect": "Allow",
      "Sid": "decrypt",
      "Resource": ["${aws_kms_key.sops_key.arn}"]
    }
  ]
}
EOF
}

resource "aws_iam_role" "secrets_repo_decrypt_role" {
  name = "${var.cluster_name}-secrets-decrypt"
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

resource "aws_iam_role_policy_attachment" "secrets_repo_decrypt_role_attach" {
  role       = aws_iam_role.secrets_repo_decrypt_role.name
  policy_arn = aws_iam_policy.secrets_repo_decrypt_policy.arn
}