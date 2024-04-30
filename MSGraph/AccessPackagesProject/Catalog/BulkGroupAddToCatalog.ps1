function AddGroupToCatalogResourceBulk
{
  param (
    [System.String]$AADGroupname,
    [System.String]$catalogid
  )
  #Assigns Variable aadgrpid 
  $aadgrpid = (Get-MgGroup -Filter ("DisplayName eq '$($AADGroupname)'")).Id

  $accessPackageResource = @{
  "originSystem" = "AadGroup"
  "OriginId" = $aadgrpid
  }

  #https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.beta.identity.governance/new-mgbetaentitlementmanagementaccesspackageresourcerequest?view=graph-powershell-betaa
  New-MgBetaEntitlementManagementAccessPackageResourceRequest -CatalogId $catalogid -RequestType "AdminAdd" -AccessPackageResource $accessPackageResource | Select Id, RequestState | ConvertTo-Json
}


# Targets catalog ID with display name options
$catalogid = (Get-MgBetaEntitlementManagementAccessPackageCatalog -Filter ("DisplayName eq 'AWS-Catalog'")).Id
$csvGroup = Import-Csv "PowerShell\O365 Cloud Scripts\MSGraph\AccessPackagesProject\Catalog\GroupName.csv"

#Auto Adder of groups to Catalog
ForEach($Line in $csvGroup)
{
  AddGroupToCatalogResourceBulk -AADGroupname $Line.AADGroupname -CatalogId $catalogid
}