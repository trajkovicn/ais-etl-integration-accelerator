# Development deployment

The Bicep templates are the source of truth. `infra/arm/azuredeploy.json` is the compiled artifact used by the Deploy to Azure button.

## Compile the template

Install the Bicep CLI, then run from the repository root:

```powershell
.\scripts\powershell\build_arm.ps1
```

Alternatively, when Azure CLI manages Bicep:

```powershell
az bicep build --file .\infra\bicep\main.bicep --outfile .\infra\arm\azuredeploy.json
```

Commit changes to both the Bicep source and generated ARM artifact so button deployments match local deployments.

## Validate before deployment

Use a development parameter file with a real Microsoft Entra object ID:

```powershell
az deployment group validate `
  --resource-group <resource-group> `
  --template-file .\infra\bicep\main.bicep `
  --parameters .\infra\bicep\parameters\dev.bicepparam
```

Validation requires Azure authentication, subscription access, registered providers, and a target resource group. It does not prove connector behavior or production readiness.

## Build the utilities

```powershell
dotnet build .\ais-etl-integration-accelerator.sln
```

The utilities authenticate with `DefaultAzureCredential`; do not place secrets in parameter files or source control.
