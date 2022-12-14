<!-- omit in toc -->
# azure-terraform-oidc

This repo contains the following code examples:

- Steps to configure OpenID Connect (OIDC) for GitHub authentication with Azure.
- Terraform backend config for OIDC.
- Terraform provider config for OIDC.

<!-- omit in toc -->
## Contents

- [Create Azure AD Application, Service Principal, and Federated Credential](#create-azure-ad-application-service-principal-and-federated-credential)
- [Assign RBAC Role to Subscription](#assign-rbac-role-to-subscription)
- [Create Terraform Backend Storage and Assign RBAC Role to Container](#create-terraform-backend-storage-and-assign-rbac-role-to-container)
- [Create GitHub Repository Secrets](#create-github-repository-secrets)
- [Running the Terraform Workflow](#running-the-terraform-workflow)
- [Cleanup](#cleanup)

## Create Azure AD Application, Service Principal, and Federated Credential

```bash
# login
az login

# vars
APP_REG_NAME='github_oidc'
GITHUB_REPO_OWNER='adamrushuk'
GITHUB_REPO_NAME='azure-terraform-oidc'

# create app reg / sp
APP_CLIENT_ID=$(az ad app create --display-name "$APP_REG_NAME" --query appId --output tsv)
az ad sp create --id "$APP_CLIENT_ID" --query appId --output tsv

# create Azure AD federated identity credential
# subject examples: https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azcli#github-actions-example
APP_OBJECT_ID=$(az ad app show --id "$APP_CLIENT_ID" --query id --output tsv)

cat <<EOF > cred_params.json
{
  "name":"${GITHUB_REPO_OWNER}-${GITHUB_REPO_NAME}-federated-identity",
  "issuer":"https://token.actions.githubusercontent.com",
  "subject":"repo:${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}:ref:refs/heads/main",
  "description":"${GITHUB_REPO_OWNER} ${GITHUB_REPO_NAME} main branch",
  "audiences":["api://AzureADTokenExchange"]
}
EOF

az ad app federated-credential create --id $APP_OBJECT_ID --parameters cred_params.json
```

## Assign RBAC Role to Subscription

Run the code below to assign the `Contributor` RBAC role to the Subscription:

```bash
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
az role assignment create --role "Contributor" --assignee "$APP_CLIENT_ID" --subscription "$SUBSCRIPTION_ID"
```

## Create Terraform Backend Storage and Assign RBAC Role to Container

Run the code below to create the Terraform storage and assign the `Storage Blob Data Contributor` RBAC role to the
container:

```bash
# vars
PREFIX='arshzgh'
LOCATION='eastus'
TERRAFORM_STORAGE_RG="${PREFIX}-rg-tfstate"
TERRAFORM_STORAGE_ACCOUNT="${PREFIX}sttfstate${LOCATION}"
TERRAFORM_STORAGE_CONTAINER="terraform"

# resource group
az group create --location "$LOCATION" --name "$TERRAFORM_STORAGE_RG"

# storage account
STORAGE_ID=$(az storage account create --name "$TERRAFORM_STORAGE_ACCOUNT" \
  --resource-group "$TERRAFORM_STORAGE_RG" --location "$LOCATION" --sku "Standard_LRS" --query id --output tsv)

# storage container
az storage container create --name "$TERRAFORM_STORAGE_CONTAINER" --account-name "$TERRAFORM_STORAGE_ACCOUNT"

# define container scope
TERRAFORM_STORAGE_CONTAINER_SCOPE="$STORAGE_ID/blobServices/default/containers/$TERRAFORM_STORAGE_CONTAINER"
echo $TERRAFORM_STORAGE_CONTAINER_SCOPE

# assign rbac
az role assignment create --assignee "$APP_CLIENT_ID" --role "Storage Blob Data Contributor" \
  --scope "$TERRAFORM_STORAGE_CONTAINER_SCOPE"
```

## Create GitHub Repository Secrets

Create the following [GitHub Repository Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository), using the code examples to show the required values:

`ARM_CLIENT_ID`

```bash
# use existing variable from previous step
echo $APP_CLIENT_ID

# or use display name
az ad app list --display-name "$APP_REG_NAME" --query [].appId --output tsv
```

`ARM_SUBSCRIPTION_ID`

```bash
az account show --query id --output tsv
```

`ARM_TENANT_ID`
  
```bash
az account show --query tenantId --output tsv
```

## Running the Terraform Workflow

Once all previous steps have been successfully completed, follow the steps below to run the `terraform` workflow:

1. Under your repository name, click `Actions`.
1. In the left sidebar, click the `terraform` workflow.
1. Above the list of workflow runs, select `Run workflow`.
1. (optional) Check the `Enable destroy mode for Terraform` checkbox to run Terraform Plan in "destroy mode".
1. Click `Run workflow`

## Cleanup

Use the code below to remove all created resources from this demo:

```bash
# login
az login

# vars
APP_REG_NAME='github_oidc'
PREFIX='arshzgh'

# remove app reg
APP_CLIENT_ID=$(az ad app list --display-name "$APP_REG_NAME" --query [].appId --output tsv)
az ad app delete --id "$APP_CLIENT_ID"

# list then remove resource groups (prompts before deletion)
QUERY="[?starts_with(name,'$PREFIX')].name"
az group list --query "$QUERY" --output table
for resource_group in $(az group list --query "$QUERY" --output tsv); do echo "Delete Resource Group: ${resource_group}"; az group delete --name ${resource_group}; done
```
