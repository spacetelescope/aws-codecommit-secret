# aws-codecommit-secret
Terraform code to set up secure secrets storage with codecommit+kms

## Quickstart

(Space Telescope Centric for now)

### Setting up role to run terraform

Use a role that has IAM permissions to create a new role that'll have just
enough permissions to actually set up CodeCommit + KMS.

1. `cd terraform-role`
2. `cp your-vars.tfvars.example your-vars.tfvars`
3. Edit `your-vars.tfvars` to the configuration you would like. Make sure you
   add your own user's arn to the list of allowed users, and set up a repo_name
   that will not clash with other people testing this out.
4. Run `terraform init`
5. Assume the role that can setup IAM permissions, and then run `terraform apply`.
   If using [awsudo](https://github.com/makethunder/awsudo) and are working with
   the AWS-DMD-TEST account, you can run:

   ```bash
   awsudo arn:aws:iam::162808325377:role/IAMRoleAdministrator terraform apply
   ```

6. This should hopefully complete, and give you a role you can use to actually
   set up CodeCommit, KMS, etc.


### Setting up CodeCommit + AWS

1. Make sure you're in the root of this repo
2. `cp your-vars.tfvars.example your-vars.tfvars`
3. Edit `your-vars.tfvars` to the configuration you would like. Make sure you
   add your own user's arn to the list of allowed users, and set up a repo_name
   that will not clash with other people testing this out.
4. Run `terraform init`
5. Assume the role you got from the previous step, and run terraform apply.
   If using [awsudo](https://github.com/makethunder/awsudo) and are working with
   the AWS-DMD-TEST account, you can run:

   ```bash
   awsudo arn:aws:iam::162808325377:role/<your-repo-name>-secrets-setup-role terraform apply
   ```
6. This should hopefully run to completion, and set up CodeCommit, KMS and produce a
   `.sops.yaml` file that can be used with sops!