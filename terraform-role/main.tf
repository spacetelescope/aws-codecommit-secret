terraform {
  required_version = ">= 0.12.6"
}

provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
}


resource "aws_iam_policy" "codecommit_secrets_setup_policy" {
  name = "${var.cluster_name}-secrets-setup"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "codecommit:CreateRepository",
        "codecommit:DeleteRepository",
        "codecommit:GetRepository",
        "codecommit:ListRepositories",
        "codecommit:ListTagsForResource"
      ],
      "Effect": "Allow",
      "Sid": "1",
      "Resource": "*"
    },
    {
      "Action": [
        "kms:CreateKey",
        "kms:DescribeKey",
        "kms:GetKeyPolicy",
        "kms:GetKeyRotationStatus",
        "kms:ListResourceTags",
        "kms:ScheduleKeyDeletion"
      ],
      "Effect": "Allow",
      "Sid": "2",
      "Resource": "*"
    },
    {
      "Action": [
        "iam:CreateRole",
        "iam:GetRole",
        "iam:DeleteRole",
        "iam:CreatePolicy",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicyVersions",
        "iam:ListAttachedRolePolicies",
        "iam:DeletePolicy",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:ListInstanceProfilesForRole"
      ],
      "Effect": "Allow",
      "Sid": "3",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "codecommit_secrets_setup_role" {
  name = "${var.cluster_name}-secrets-setup-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::162808325377:user/yuvipanda"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codecommit_secrets_setup_attachment" {
  role       = aws_iam_role.codecommit_secrets_setup_role.name
  policy_arn = aws_iam_policy.codecommit_secrets_setup_policy.arn
}