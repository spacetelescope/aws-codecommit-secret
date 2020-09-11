terraform {
  required_version = ">= 0.12.6"
}

provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
}

data "aws_iam_policy_document" "codecommit_secrets_setup_policy_document" {
  statement {
    sid = "1"
    actions = [
      "codecommit:CreateRepository",
      "codecommit:DeleteRepository",
      "codecommit:GetRepository",
      "codecommit:ListRepositories",
      "codecommit:ListTagsForResource",
      "codecommit:TagResource"
    ]

    resources = ["*"]
  }

  statement {
    sid = "2"
    actions = [
      "kms:CreateKey",
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListResourceTags",
      "kms:ScheduleKeyDeletion"
    ]

    resources = ["*"]
  }

  statement {
    sid = "3"
    actions = [
      "iam:CreateRole",
      "iam:GetRole",
      "iam:DeleteRole",
      "iam:CreatePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:ListAttachedRolePolicies",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListInstanceProfilesForRole",
      "iam:UpdateAssumeRolePolicy"
    ]
    resources = ["*"]
  }

statement {
    sid = "4"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:CreateAccessPoint",
      "s3:CreateBucket",
      "s3:CreateJob",
      "s3:DeleteAccessPoint",
      "s3:DeleteBucket",
      "s3:DeleteBucketWebsite",
      "s3:DeleteJobTagging",
      "s3:DeleteObject",
      "s3:DeleteObjectTagging",
      "s3:DeleteObjectVersion",
      "s3:DeleteObjectVersionTagging",
      "s3:DescribeJob",
      "s3:GetAccelerateConfiguration",
      "s3:GetAccessPoint",
      "s3:GetAccessPointPolicy",
      "s3:GetAccessPointPolicyStatus",
      "s3:GetAccountPublicAccessBlock",
      "s3:GetAnalyticsConfiguration",
      "s3:GetBucketAcl",
      "s3:GetBucketCORS",
      "s3:GetBucketLocation",
      "s3:GetBucketLogging",
      "s3:GetBucketNotification",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketPolicy",
      "s3:GetBucketPolicyStatus",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketRequestPayment",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketWebsite",
      "s3:GetEncryptionConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetJobTagging",
      "s3:GetLifecycleConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectLegalHold",
      "s3:GetObjectRetention",
      "s3:GetObjectTagging",
      "s3:GetObjectTorrent",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionTorrent",
      "s3:GetReplicationConfiguration",
      "s3:HeadBucket",
      "s3:ListAccessPoints",
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
      "s3:ListJobs",
      "s3:ListMultipartUploadParts",
      "s3:PutAccelerateConfiguration",
      "s3:PutAnalyticsConfiguration",
      "s3:PutBucketCORS",
      "s3:PutBucketLogging",
      "s3:PutBucketNotification",
      "s3:PutBucketObjectLockConfiguration",
      "s3:PutBucketRequestPayment",
      "s3:PutBucketTagging",
      "s3:PutBucketVersioning",
      "s3:PutBucketWebsite",
      "s3:PutEncryptionConfiguration",
      "s3:PutInventoryConfiguration",
      "s3:PutJobTagging",
      "s3:PutLifecycleConfiguration",
      "s3:PutMetricsConfiguration",
      "s3:PutObject",
      "s3:PutObjectLegalHold",
      "s3:PutObjectRetention",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
      "s3:PutReplicationConfiguration",
      "s3:ReplicateDelete",
      "s3:ReplicateObject",
      "s3:ReplicateTags",
      "s3:RestoreObject",
      "s3:UpdateJobPriority",
      "s3:UpdateJobStatus"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "codecommit_secrets_setup_policy" {
  name = "${var.repo_name}-setup"
  policy = data.aws_iam_policy_document.codecommit_secrets_setup_policy_document.json
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "codecommit_secrets_role_assumption_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "AWS"
      identifiers = var.allowed_roles
    }
  }
}

resource "aws_iam_role" "codecommit_secrets_setup_role" {
  name = "${var.repo_name}-setup"
  assume_role_policy = data.aws_iam_policy_document.codecommit_secrets_role_assumption_policy_document.json
}

resource "aws_iam_role_policy_attachment" "codecommit_secrets_setup_attachment" {
  role       = aws_iam_role.codecommit_secrets_setup_role.name
  policy_arn = aws_iam_policy.codecommit_secrets_setup_policy.arn
}
