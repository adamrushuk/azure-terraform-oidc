#! /usr/bin/env bash
#
# terraform build

# ensure strict mode and predictable pipeline failure
set -euo pipefail
trap "echo 'error: Script failed: see failed command above'" ERR

# init
# use partial backend config: https://developer.hashicorp.com/terraform/language/settings/backends/configuration#command-line-key-value-pairs
terraform init \
    -backend-config="resource_group_name=$TERRAFORM_STORAGE_RG" \
    -backend-config="storage_account_name=$TERRAFORM_STORAGE_ACCOUNT"

# validate
terraform validate

# apply
# -var="VAR_NAME=VAR_VALUE"
terraform apply -auto-approve
