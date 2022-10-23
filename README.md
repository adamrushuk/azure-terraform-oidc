# azure-terraform-oidc

Testing OpenID Connect from GitHub to Azure.

## Create Azure AD Application and Service Principal

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
  "subject":"repo:${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}:refs:refs/heads/main",
  "description":"${GITHUB_REPO_OWNER} ${GITHUB_REPO_NAME} main branch",
  "audiences":["api://AzureADTokenExchange"],
}
EOF

az ad app federated-credential create --id $APP_OBJECT_ID --parameters cred_params.json
```

## Assign RBAC Role to Subscription

Run the code below to assign the `Contributor` RBAC role to your Subscription:

```bash
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
az role assignment create --role "Contributor" --assignee "$APP_CLIENT_ID" --subscription "$SUBSCRIPTION_ID"
```

## Create GitHub Repository Secrets

Create the following [GitHub Repository Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository), using the code examples to show the required values:

`ARM_TENANT_ID`
  
```bash
az account show --query tenantId --output tsv
```

`ARM_SUBSCRIPTION_ID`

```bash
az account show --query id --output tsv
```

`ARM_CLIENT_ID`

```bash
# using existing variable from previous step
echo $APP_CLIENT_ID

# using display name
az ad app list --display-name "$APP_REG_NAME" --query [].appId --output tsv
```
