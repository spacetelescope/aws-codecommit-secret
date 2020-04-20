# KMS + CodeCommit for Hubploy Secrets

This repo contains [terraform](https://terraform.io/) code to
set up a secure, AWS internal way to store secret YAML files
for use with [hubploy](https://github.com/yuvipanda/hubploy).

## Features

1. No service AWS users are required, so no chances of leaking AWS
   access credentials via this mechanism.
2. A single KMS [CMK](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys)
   will be used for encryption / decryption. sops uses [envelope
   encryption](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#enveloping)
   with per-file data keys, as is recommended AWS practice.
3. All secrets are stored after encryption in an [AWS CodeCommit](https://aws.amazon.com/codecommit)
   repository inside the same account. No secrets, encrypted or otherwise,
   will ever hit any GitHub repository.
4. IAM roles will be used for access controls. One role will have permissions to
   pull secrets from the AWS CodeCommit repo and decrypt them, but nothing
   more. Another role could decrypt, encrypt new files, and update secrets.
   During deployment, only the read-only role will be used, while developers
   updating secrets can assume the read-write role as needed.

## Setting up

The repo sets up the following:

1. IAM roles required for setting up KMS + CodeCommit
2. IAM roles for decrypt+read-only access to the secret YAML files
3. IAM roles for encrypt+read-write access to the secret YAML files
4. An empty [AWS CodeCommit](https://aws.amazon.com/codecommit/) repo
   that will be used to store the secret YAML files.
5. A KMS [CMK](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys)
   that will be used for encryption / decryption.

### Setting up IAM role to run terraform

Terraform is used to create the CodeCommit, KMS and other resources
needed for versioned secret storage. However, the principle of
[least privilege](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege)
applies to the role executing the Terraform code itself. With that in mind,
a smaller Terraform module (in `terraform-iam`) provisions
least privileged IAM roles for use with the main terraform module
(in `kms-codecommit`). This ensures that we have strong controls
over what Terraform can and can not do.

Here is how you can set up these roles.

1. `cd terraform-iam`
2. Run `terraform init` here if you have not already done so.
3. You need to configure this terraform module to match your preferences.
   There is a template file, in `your-vars.tfvars.example`. This can be copied
   into a `your-vars.tfvars` file, and then edited to match what you would
   like.

   Currently supported variables are:

   a. **region** - the AWS region all these resources would be created in.
      Defaults to `us-east-1`

   b. **repo_name** - Name of the AWS CodeCommit repo that is going to be
      created. This is used in determining name of roles, etc. Use something
      unique - you will clash with other users using the same name otherwise.
      *Required*

   c. **allowed_users** - List of user ARNs who can assume the roles created
      here. Users in this list can make modifications to the KMS + CodeCommit
      setup. Make sure to add your own ARN here. *Required*

4. Assume a role that has permissions to create new IAM resources. [awsudo]
   (https://github.com/makethunder/awsudo) is a wonderful tool for executing
   commands with an assumed role in a clear fashion. If your organization
   has a role with, say, an ARN of `arn:aws:iam::162808325377:role/IAMRoleAdministrator`,
   you can then assume the role and execute terraform module with:

   ```bash
   awsudo arn:aws:iam::162808325377:role/IAMRoleAdministrator terraform apply -var-file=your-vars.tfvars
   ```

5. When completed, this should have created an IAM role with just enough
   permissions to run the *main* module in `kms-codecommit`. The role is named
   `<repo-name>-setup`, and will be present in the output of the
   previous `terraform apply` command.


If you want to add / remove *users* who can modify the KMS + CodeCommit setup,
you would add them to the `allowed_users` section of the `tfvars` file, and run
`terraform apply` again. Otherwise, this is pretty static.

### Setting up KMS + CodeCommit

Now that we have a role for setting up KMS + CodeCommit, we can do so!

1. From the root of the repo, `cd kms-codecommit`.
2. Run `terraform init` here if you had not done so.
3. You need to configure this terraform module to match your preferences.
   There is a template file, in `your-vars.tfvars.example`. This can be copied
   into a `your-vars.tfvars` file, and then edited to match what you would
   like.

   Currently supported variables are:

   a. **region** - the AWS region all these resources would be created in.
      Defaults to `us-east-1`

   b. **repo_name** - Name of the AWS CodeCommit repo that is going to be
      created. This is used in determining name of roles, etc. Use something
      unique - you will clash with other users using the same name otherwise.
      *Required*

   c. **decrypt_allowed_users** - ARNs of users who can assume the role required
      to pull and decrypt secrets. They can not make new secret files, nor can they
      push modified secret files.

   d. **encrypt_allowed_users** - ARNs of users who can assume the role required
      to encrypt secrets and push them.

4. Assume the IAM role from the previous step, and run `terraform apply`.
   For example,

   ```bash
   awsudo arn:aws:iam::<account-id>:role/<your-repo-name>-setup terraform apply -var-file=your-vars.tfvars
   ```
5. This should hopefully run to completion, and set up CodeCommit, KMS and appropriate IAM roles.
   It should produce a `.sops.yaml` file that can be used with your new repo for appropriate
   encryption with [sops](https://github.com/mozilla/sops).