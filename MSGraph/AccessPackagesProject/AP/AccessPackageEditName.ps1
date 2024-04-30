# This script will be used to change the name of the Access Packages via csv
#Authenticate to Azure Tenant
Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All"

Import-Module Microsoft.Graph.Beta.Identity.Governance

#Csv file to powershell object 
$csvFile = Import-Csv  "PowerShell\O365 Cloud Scripts\MSGraph\AccessPackagesProject\AP\AccessPKGEditName.csv"


#Forloop to control the commandlet
Foreach ($AccessPKGName in $csvFile)
{
    # Holds AccessPKG ID
    $accesspkgid = Get-MgBetaEntitlementManagementAccessPackage -Filter  "Displayname eq '$($AccessPKGName.CurrentName)'" | Select-Object -ExpandProperty Id
    # Updates the Name with using accessPKG ID
    Update-MgBetaEntitlementManagementAccessPackage -AccessPackageId $accesspkgId -DisplayName $AccessPKGName.NewName

}