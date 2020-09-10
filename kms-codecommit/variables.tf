variable "region" {
  default = "us-east-1"
}

variable "repo_name" {
  default = "<change-this-in-tfvars>"
}

variable "sops_s3_bucket" {
  default = "<change-this-in-tfvars>"
}

variable "sops_s3_key" {
  default = "<change-this-in-tfvars>"
}

variable "sops_s3_source" {
  default = "<change-this-in-tfvars>"
}

variable "encrypt_allowed_roles" {
  default = []
}

variable "decrypt_allowed_roles" {
  default = []
}
