# Terraform Cloud AWS OIDC bootstrap

Create an IAM OIDC identity provider for `https://app.terraform.io` (audience `aws.workload.identity`) if your AWS account does not already have one. Then create a role for Terraform Cloud runs.

Use a trust policy constrained to the exact Terraform Cloud organization/project/workspace. Example subject pattern (replace all placeholders; prefer exact workspace subject):

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/app.terraform.io"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "app.terraform.io:aud": "aws.workload.identity"
      },
      "StringLike": {
        "app.terraform.io:sub": "organization:ORG_NAME:project:PROJECT_NAME:workspace:WORKSPACE_NAME:run_phase:*"
      }
    }
  }]
}
```

Attach a permissions policy that allows the resources in this project to be managed. For an interview exercise, explain that production would split provisioning and runtime roles, scope IAM permissions by resource where AWS supports it, and use permission boundaries/SCPs. Avoid long-lived access keys.
