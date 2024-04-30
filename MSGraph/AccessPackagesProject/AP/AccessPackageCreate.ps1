<#
This script is used create Access packages through csv automation
#>
#########################################
#1. Connect to MS Graph Powershell SDK:-
#########################################

Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All"
Import-Module Microsoft.Graph.Beta.Identity.Governance

#Pulls in the main variables that are needed for the script below via csvFile Object and String Variables for CatalogID
$csvFile = Import-Csv  "MSGraph/AccessPackagesProject/AP/AccessPKGCreateInfo.csv"
$CatalogName = "AWS-Catalog"
$CatalogID = (Get-MgBetaEntitlementManagementAccessPackageCatalog -filter "DisplayName eq '$($CatalogName)'").Id


foreach($line in $csvFile)
{
    try {
        $accesspkgid = New-MgBetaEntitlementManagementAccessPackage -CatalogId $catalogid -DisplayName $line.AccessPackageName -Description $line.AccessPackageDesc 
    
        Write-Host "#############################################################################################"
        Write-Host "Access Package $($line.AccessPackageName) has been added to the Catalog $($CatalogName) successfully."
        Write-Host "#############################################################################################"
    } catch {
        Write-Host "#############################################################################################"
        Write-Host "Failed to add Access Package $($line.AccessPackageName) to the Catalog $($CatalogName)."
        Write-Host "Error: $_"
        Write-Host "#############################################################################################"
    }
}