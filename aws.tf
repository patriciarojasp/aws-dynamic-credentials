# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = "us-east-1"
}

# Data source used to grab the TLS certificate for Terraform Cloud.
#
# https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate
data "tls_certificate" "tfc_certificate" {
  url = "https://${var.tfc_hostname}"
}

# Data source to reference the existing OIDC provider for Terraform Cloud
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider
data "aws_iam_openid_connect_provider" "tfc_provider" {
  url = "https://${var.tfc_hostname}"
}

# Uncomment the resource below if you DON'T have an existing OIDC provider for Terraform Cloud
# and comment out the data source above
#
# resource "aws_iam_openid_connect_provider" "tfc_provider" {
#   url             = data.tls_certificate.tfc_certificate.url
#   client_id_list  = [var.tfc_aws_audience]
#   thumbprint_list = [data.tls_certificate.tfc_certificate.certificates[0].sha1_fingerprint]
# }

# Creates a role which can only be used by the specified Terraform
# cloud workspace.
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "tfc_role_dynamic_creds" {
  name = "tfc-role-dynamic-creds"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Principal": {
       "Federated": "${data.aws_iam_openid_connect_provider.tfc_provider.arn}"
     },
     "Action": "sts:AssumeRoleWithWebIdentity",
     "Condition": {
       "StringEquals": {
         "${var.tfc_hostname}:aud": "${var.tfc_aws_audience}"
       },
       "StringLike": {
         "${var.tfc_hostname}:sub": "organization:${var.tfc_organization_name}:*"
       }
     }
   }
 ]
}
EOF
}

# Creates a policy that will be used to define the permissions that
# the previously created role has within AWS.
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "tfc_policy_dynamic_creds" {
  name        = "tfc-policy-dynamic-creds"
  description = "TFC run policy"

  policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
       "ec2:*",
       "vpc:*",
       "s3:*",
       "rds:*",
       "lambda:*",
       "apigateway:*",
       "cloudformation:*",
       "cloudwatch:*",
       "logs:*",
       "iam:ListRoles",
       "iam:ListPolicies",
       "iam:ListInstanceProfiles",
       "iam:GetRole",
       "iam:GetPolicy",
       "iam:GetPolicyVersion",
       "iam:GetInstanceProfile",
       "iam:PassRole",
       "iam:CreateRole",
       "iam:CreatePolicy",
       "iam:CreateInstanceProfile",
       "iam:AttachRolePolicy",
       "iam:DetachRolePolicy",
       "iam:AddRoleToInstanceProfile",
       "iam:RemoveRoleFromInstanceProfile",
       "iam:UpdateRole",
       "iam:UpdateAssumeRolePolicy",
       "iam:DeleteRole",
       "iam:DeletePolicy",
       "iam:DeleteInstanceProfile",
       "iam:TagRole",
       "iam:UntagRole",
       "iam:TagPolicy",
       "iam:UntagPolicy",
       "elasticloadbalancing:*",
       "autoscaling:*",
       "route53:*",
       "acm:*",
       "secretsmanager:*",
       "ssm:*",
       "kms:*",
       "sns:*",
       "sqs:*",
       "dynamodb:*",
       "elasticache:*",
       "ecs:*",
       "ecr:*",
       "eks:*",
       "application-autoscaling:*",
       "elasticfilesystem:*",
       "elasticbeanstalk:*",
       "cloudfront:*",
       "wafv2:*",
       "backup:*",
       "events:*",
       "scheduler:*",
       "tag:*"
     ],
     "Resource": "*"
   }
 ]
}
EOF
}

# Creates an attachment to associate the above policy with the
# previously created role.
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "tfc_policy_attachment" {
  role       = aws_iam_role.tfc_role_dynamic_creds.name
  policy_arn = aws_iam_policy.tfc_policy_dynamic_creds.arn
}