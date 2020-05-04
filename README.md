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

## Demo

Here's a quick demo of how developers will use this infrastructure to encrypt,
decrypt and update secrets.

[![asciicast](https://asciinema.org/a/322006.svg)](https://asciinema.org/a/322006)

More detailed usage information is [provided below](#using-a-repo-for-secrets)

## Setting up the infrastructure

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
   (https://github.com/meltwater/awsudo
   ) is a wonderful tool for executing
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

### Setting up repo to be used with sops

Once your CodeCommit repo has been set up, you need to add the `.sops.yaml` file.
This tells `sops` which KMS keys to use for encryption and decryption.

1. Make sure you have the [pre-requisites](#pre-requisites) installed

2. [Get a copy of the repo](#getting-a-copy-of-the-repo). `git` will
   give you a warning about the repo being empty. This is expected.

3. Copy the `.sops.yaml` file produced in the earlier stage into the
   freshly cloned repo.

4. Add `.sops.yaml` to the git repo and make a commit.

   ```bash
   git add .sops.yaml
   git commit -m "Added initial .sops.yaml" file
   ```

5. Push the new commit to the CodeCommit repository.

   ```bash
   awsudo <arn-of-encrypt-permission-role> git push origin master
   ```

6. Tada! Your CodeCommit git repo has now been initialized to
   be used with `sops`. You can now start using it to store
   secrets.

## Using a repo for secrets

Once set up, we will use [sops](https://github.com/mozilla/sops) to view,
decrypt and encrypt secrets.

### Pre-requisites

1. AWS' [git-remote-codecommit](https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-git-remote-codecommit.html)
   for authentication to CodeCommit with IAM roles.
2. [sops](https://github.com/mozilla/sops)

### Getting a copy of the repo

1. Construct the git clone URL by following the template
   **codecommit::<region>://<repo-name>**. If your repo name is
   `yuvi-secrets` in us-east-1, your repo url would be
   `codecommit::us-east-1://yuvi-secrets`.

2. Clone the repo after assuming a read-only or read-write IAM role.

   a. In an EC2 instance with appropriate roles, you can simply run:

      ```bash
      git clone <codecommit-url>
      ```

      It'll pick up the proper credentials from EC2, and clone the
      repo.

   b. If you are on a local computer, you need to first assume an
      appropriate role before running the `git clone` command.
      If you were using `awsudo`, it would be:

      ```bash
      awsudo <arn-of-role> git clone <codecommit-url>
      ```

3. Now you have a copy of the repo! All files inside will be encrypted -
   you can not see *anything* without explicitly decrypting it. Other than that,
   it is a standard git repository - so commands like `git commit`, `git checkout`,
   etc will work as usual. However, commands that push or pull data - like
   `git push` or `git pull`, require IAM roles to work. This would require an
   EC2 instance with appropriate roles, or `awsudo` with approprite role ARN.

### Decrypting and viewing secrets

1. With `sops` installed, you can just run:

   ```
   sops <filename>
   ```

   to decrypt and view the files. If you have the appropriate roles to access
   the KMS key, it will 'just work'. If not, it'll throw an error. The readonly
   roles generated by terraform have Decrypt permission on the key, and the
   readwrite roles have Encrypt permission as well.

2. If someone with encryption permissions has updated the repo, you can still
   pull in the latest changes with the decrypt role.

   ```
   awsudo <arn-of-role> git pull origin master
   ```

### Encrypting and pushing secrets

1. To create a new file, you can run:

   ```
   sops <filename>
   ```

   and this will create the file, put you in an editor, encrypt it on save,
   and put that on disk. You need to have assumed the proper role, or this
   will fail.

2. You can then use regular git commands to commit and push. You must
   assume the role with the right permissions before doing `git push`
   as well.
