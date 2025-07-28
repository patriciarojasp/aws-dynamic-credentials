# AWS Dynamic Credentials with HCP Terraform

This repository contains Terraform configuration to set up AWS Dynamic Credentials with HCP Terraform, eliminating the need to store long-lived AWS access keys or use scripts to login with Doormat login.

## What This Does

- Creates an IAM role in AWS that can be assumed by HCP Terraform
- Sets up a global variable set in HCP Terraform for AWS authentication
- Configures the necessary trust relationship between AWS and HCP Terraform
- Provides full administrative access to AWS resources via the created role

## Prerequisites

1. **AWS Account** with administrative access (your Doormat account should work fine)
2. **HCP Terraform Account** with organization access
3. **Terraform CLI** installed locally
4. **AWS CLI** configured with credentials (for initial setup only)

## Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/patriciarojasp/aws-dynamic-credentials.git
cd aws-dynamic-credentials
```

### 2. Set Up Variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
tfc_organization_name = "your-tfc-organization-name"
```

### 3. Authenticate to HCP Terraform

First time setup requires authentication to HCP Terraform:

```bash
terraform login
```

This will:
- Open your browser to authenticate
- Store your TFC token locally
- Allow Terraform to manage your TFC resources

### 4. Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

## What Gets Created

### AWS Resources
- **IAM OIDC Provider**: References existing TFC OIDC provider
- **IAM Role**: `tfc-role-dynamic-creds` with full administrative access
- **IAM Policy**: `tfc-policy-dynamic-creds` allowing all AWS actions
- **Policy Attachment**: Links the policy to the role

### HCP Terraform Resources
- **Global Variable Set**: `AWS Dynamic Credentials`
- **Environment Variables**:
  - `TFC_AWS_PROVIDER_AUTH=true` (enables dynamic credentials)
  - `TFC_AWS_RUN_ROLE_ARN` (ARN of the created IAM role)

## Configuration Files

| File | Purpose |
|------|---------|
| `aws.tf` | AWS IAM resources (role, policy, OIDC provider) |
| `tfc-varset.tf` | HCP Terraform global variable set |
| `variables.tf` | Variable definitions |
| `terraform.tfvars` | Your specific values (not in git) |
| `terraform.tfvars.example` | Template for variables |

## Usage After Setup

Once configured, any HCP Terraform workspace in your organization will automatically have access to AWS using the dynamic credentials. No need to manually configure AWS access keys!

### In Your Terraform Configurations

Simply use the AWS provider without credentials:

```hcl
provider "aws" {
  region = "us-east-1"
  # No access_key or secret_key needed!
}
```

## Security Notes

⚠️ **Important**: This configuration grants **full administrative access** to your AWS account.

### Customizing Permissions

To restrict permissions, modify the policy in `aws.tf`:

```hcl
# Instead of "*", specify only needed actions
"Action": [
  "ec2:*",
  "s3:*",
  "rds:*"
]
```

## Troubleshooting

### OIDC Provider Configuration

By default, this configuration assumes you already have an OIDC provider for Terraform Cloud in your AWS account. If you don't:

1. **Edit `aws.tf`**:
   - Comment out the `data "aws_iam_openid_connect_provider"` block
   - Uncomment the `resource "aws_iam_openid_connect_provider"` block

2. **This will create a new OIDC provider** instead of referencing an existing one

### Common Issues

1. **"EntityAlreadyExists" for OIDC provider**
   - You already have an OIDC provider (use the default data source configuration)
   - If you want to create a new one, see OIDC Provider Configuration above

3. **Permission denied errors**
   - Ensure your AWS credentials have IAM permissions
   - Check that TFC token has organization access
