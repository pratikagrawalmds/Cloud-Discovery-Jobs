# Pipeline to extract Custom Roles and BuiltInRoles from Azure AD into a CSV file.

Create report in CSV format, containing:
  - Role Name
  - RoleID
  - Subscription ID.
  - Subscription Name.

And upload it into Azure storage account `wkservicenowdiscovery`.

## Getting Started 

### Input Parameters
There is no input parameters.

Predefined parameters:
- `inventoryFileName` default value is CustomRoles.csv and BuiltInRoles.csv
- `storageAccountSubscription` default value is GBS-ITO-RainierCldPlatform-Prod (e25f921a-492f-468e-ab0c-3052e5f208d5) 
- `storageKeyVaultName` default value is ZUSE1GBSKVTP1SERVICES
- `targetContainerName` default value is azure

### Output

- CSV file CustomRoles.csv
- CSV file BuiltInRoles.csv


