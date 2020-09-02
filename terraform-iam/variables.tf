variable "region" {
  default = "us-east-1"
}

variable "repo_name" {
  default = "<change-this-in-your-tfvars-file>"
}

variable "allowed_users" {
  default = []
}

variable "aws_secrets_account_id" {
  default = ""
}

variable "aws_secrets_account_role" {
  default = ""
}
