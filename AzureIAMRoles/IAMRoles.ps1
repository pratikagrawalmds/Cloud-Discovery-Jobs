<#
.SYNOPSIS
    This script generates inventory report and stores it in Azure Blob Storage
#>
[CmdletBinding()]
#Parameters
Param
(
    [Parameter(Mandatory = $true)]
    [String]$StorageAccountSubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]$TargetStorageAccountName,
    [Parameter(Mandatory = $true)]
    [string]$TargetStorageAccountResourceGroup,
    [Parameter(Mandatory = $true)]
    [string]$TargetContainerName,   
    [Parameter(Mandatory = $true)]
    [string]$AzIAMCustomRoles,
    [Parameter(Mandatory = $true)]
    [string]$AzIAMBuiltInRoles
)
begin {  
    #Path of the report
    $ReportFileSystemPath = "$env:Build_ArtifactStagingDirectory/azure_customroles_inventory.csv"    
    $ReportFileSystemPath2 = "$env:Build_ArtifactStagingDirectory/azure_builtinroles_inventory.csv"    

    # Turn all non-terminating errors into terminating ones
    $ErrorActionPreference = "Stop"
  
    # Suppress breaking changes warnings (https://aka.ms/azps-changewarnings)
    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
    $WarningPreference = 'SilentlyContinue'
  
    # Init flags for error handling
    $isErrorState = $false      
}  
process {
    try {
        [array]$subscriptions = Get-AzSubscription
        Write-Output "`nSubscriptions avaliable for processing: $($subscriptions.Count)"
        
        # Process each subscription and generate report
        Write-Output "`nGenerating report..." 
  
        foreach ($subscription in $subscriptions) {
            Write-Output "`nProcessing subscription $($subscriptions.IndexOf($subscription)+1) out of $($subscriptions.Count): $($subscription.Name)"                   
            # Process each subscription and generate report
            Write-Output "`nGenerating report..."   
            try {
                #$roleDefinitions=Get-AzRoleDefinition -Scope /subscriptions/$($subscription.SubscriptionId)#$roleDefinitions = Get-AzRoleDefinition
                $roleDefinitions=Get-AzRoleDefinition -Scope /subscriptions/$($subscription.SubscriptionId)
                foreach ($as in $roleDefinitions) {
                    if ($as.IsCustom -eq $true) {
                        # Generate Report Details
                        $reportDetails = [ordered]@{

                            'RoleName' = $as.Name
                            'RoleId' = $as.Id
                            'Subscription ID' = $subscription.Id
                            'Subscription Name' = $subscription.Name
                        }
                        [PSCustomObject]$reportDetails | Export-Csv -Path $ReportFileSystemPath -NoTypeInformation -Append
                    }
                    
                }
                if($subscription -eq $subscriptions[0]) {
                    foreach ($role in $roleDefinitions) {
                    # Check if the role is a built-in role and not in the excluded list
                    if (-not $role.IsCustom -and $role.Name -notin @("Owner", "Contributor", "Access Review Operator Service Role", "Role Based Access Control Administrator", "User Access Administrator")) {
                        # Generate Report Details
                        $reportDetails = [ordered]@{
                            'RoleName' = $role.Name
                            'RoleID' = $role.Id
                            'Subscription ID' = "ALL"
                            'Subscription Name' = "ALL"
                        }
                        [PSCustomObject]$reportDetails | Export-Csv -Path $ReportFileSystemPath2 -NoTypeInformation -Append
                    }         
                }
            }

            }
            catch {
                write-host $_
                $isErrorState = $true
                $catchedError = $_
            }
        }
        #Select subscription of target Storage Account
        Set-AzContext -SubscriptionId $StorageAccountSubscriptionId
        #Get Context of the destination storage account
        $targetStorageAccount = Get-AzStorageAccount -Name $TargetStorageAccountName -ResourceGroupName $TargetStorageAccountResourceGroup
        Write-Output "Uploading the result file"
      
        #Upload the file
        Set-AzStorageBlobContent -Container $TargetContainerName -File $ReportFileSystemPath -Blob $AzIAMCustomRoles -Context $targetStorageAccount.Context -Force
        Set-AzStorageBlobContent -Container $TargetContainerName -File $ReportFileSystemPath2 -Blob $AzIAMBuiltInRoles -Context $targetStorageAccount.Context -Force

        Write-Output "The result file is stored in the following location"
        Write-Output "SubcriptionId: $StorageAccountSubscriptionId"
        Write-Output "Resource Group: $TargetStorageAccountResourceGroup"
        Write-Output "Storage Account Name: $TargetStorageAccountName"
        Write-Output "Container Name: $TargetContainerName"
        Write-Output "File Paths: $AzIAMCustomRoles"
        Write-Output "File Paths: $AzIAMBuiltInRoles"
    }
    catch {
        $isErrorState = $true
        $catchedError = $_
    }
}
  
end {
    if ($isErrorState) {
        Write-Output "`nReport generated with errors."
        throw "`nLast error: $($catchedError | Out-String)"
    }
    else {
        Write-Output "`nReport generated successfully."
    }
}
