# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0
# terraform { 
#   cloud { 
    
#     organization = "var.tfc_organization_name" 

#     workspaces { 
#       name = "var.tfc_workspace_name" 
#     } 
#   } 
# }

provider "tfe" {
  hostname = var.tfc_hostname
}

# Data source used to grab the project under which a workspace will be created.
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/project
data "tfe_project" "tfc_project" {
  name         = var.tfc_project_name
  organization = var.tfc_organization_name
}

# Create a global variable set for AWS authentication
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/variable_set
resource "tfe_variable_set" "aws_auth_varset" {
  name         = "AWS Dynamic Credentials"
  description  = "Global variable set for AWS Workload Identity authentication"
  organization = var.tfc_organization_name
  global       = true
}

# Global variable to enable AWS provider authentication
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/variable
resource "tfe_variable" "enable_aws_provider_auth" {
  variable_set_id = tfe_variable_set.aws_auth_varset.id

  key      = "TFC_AWS_PROVIDER_AUTH"
  value    = "true"
  category = "env"

  description = "Enable the Workload Identity integration for AWS."
}

# Global variable for AWS role ARN
resource "tfe_variable" "tfc_aws_role_arn" {
  variable_set_id = tfe_variable_set.aws_auth_varset.id

  key      = "TFC_AWS_RUN_ROLE_ARN"
  value    = aws_iam_role.tfc_role_dynamic_creds.arn
  category = "env"

  description = "The AWS role arn runs will use to authenticate."
}

# The following variables are optional; uncomment the ones you need!

# resource "tfe_variable" "tfc_aws_audience" {
#   workspace_id = tfe_workspace.my_workspace.id

#   key      = "TFC_AWS_WORKLOAD_IDENTITY_AUDIENCE"
#   value    = var.tfc_aws_audience
#   category = "env"

#   description = "The value to use as the audience claim in run identity tokens"
# }

# The following is an example of the naming format used to define variables for
# additional configurations. Additional required configuration values must also
# be supplied in this same format, as well as any desired optional configuration
# values.
#
# Additional configurations can be used to uniquely authenticate multiple aliases
# of the same provider in a workspace, with different roles/permissions in different
# accounts or regions.
#
# See https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/specifying-multiple-configurations
# for more details on specifying multiple configurations.
#
# See https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration#specifying-multiple-configurations
# for specific requirements and details for the AWS provider.

# resource "tfe_variable" "enable_aws_provider_auth_other_config" {
#   workspace_id = tfe_workspace.my_workspace.id

#   key      = "TFC_AWS_PROVIDER_AUTH_other_config"
#   value    = "true"
#   category = "env"

#   description = "Enable the Workload Identity integration for AWS for an additional configuration named other_config."
# }