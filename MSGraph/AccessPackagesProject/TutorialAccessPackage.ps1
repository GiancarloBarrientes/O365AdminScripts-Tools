
<#
ARTICLE THAT GOES IN TO THIS pretty good has a webinar with author of the script
https://github.com/arindam0310018/24-Feb-2023-Microsoft-Graph-Powershell_Create-Catalog-AccessPackage-Roles-Policies
#>

###############
# VARIABLES:- These variables will be used in a csv for each Access Package Creation
###############


<# Current working portion of the script
$CatalogName = "AWS-Catalog"
$CatalogDesc = "AWS Catalog"
$AADGroupname = "Cloud Group1"
$AccessPackageName = "AWS-Access-Pkge"
$AccessPackageDesc = "AWS Environment Access Package"
$scopetype = "NoSubjects"
$acceptrequests = "$false"
$accesspkgapprovalreq = "$true"
$accesspkgapprovalreqext = "$false"
$accesspkgrequestorjustify = "$false"
$AccessPackagePolicyName = "Administrator managed (365 days)"
$AccessPackagePolicyDesc = "admin managed policy"
$duration = "365"
#>
<# Need to figure out how this plays in the grand scheme of things
$AADGrpCatalogowner = "AM-Lab-Catalog-Owner"
$AADGrpCatalogreader = "AM-Lab-Catalog-Reader"
$AADGrpCatalogaccesspackagemanager = "AM-Lab-Catalog-AccessPackage-Manager"
$AADGrpCatalogaccesspackageassignmentmanager = "AM-Lab-Catalog-AccessPackage-Assignment-Manager"
#############################################
# The below Role Ids are constant values:-
#############################################
$roleidCatalogowner = "ae79f266-94d4-4dab-b730-feca7e132178"
$roleidCatalogreader = "44272f93-9762-48e8-af59-1b5351b1d6b3"
$roleidAccesspackagemanager = "7f480852-ebdc-47d4-87de-0d8498384a83"
$roleidAccesspackageassignmentmanager = "e2182095-804a-4656-ae11-64734e9b7ae5"
#>

#Pulls in the main variables that are needed for the script below via csvFile Object
$csvFile = Import-Csv  "PowerShell\O365 Cloud Scripts\MSGraph\AccessPackagesProject\AccessPkgInfo.csv"
$csvGroup = Import-Csv "PowerShell\O365 Cloud Scripts\MSGraph\AccessPackagesProject\GroupName.csv"

#################
# CORE SCRIPT:- 
#################

#########################################
#1. Connect to MS Graph Powershell SDK:-
#########################################

Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All"

#Import-Module Microsoft.Graph.DeviceManagement.Enrollment

####################################################
#2. Create Catalog and get the Catalog Identifier:-
####################################################

$catalogid = New-MgBetaEntitlementManagementAccessPackageCatalog -DisplayName $csvFile.CatalogName -Description $csvFile.CatalogDesc | Select -ExpandProperty Id

Write-Host "##############################################"
Write-Host "Catalog $CatalogName created successfully."
Write-Host "##############################################"

<#
########################################################################
#3. Create AAD Groups and configure Catalog Roles and Administrator:- 
########################################################################

$AADGrpCatalogownerid = az ad group create --display-name $AADGrpCatalogowner --mail-nickname $AADGrpCatalogowner --query "id" -o tsv
$AADGrpCatalogreaderid = az ad group create --display-name $AADGrpCatalogreader --mail-nickname $AADGrpCatalogreader --query "id" -o tsv
$AADGrpCatalogaccesspackagemanagerid = az ad group create --display-name $AADGrpCatalogaccesspackagemanager --mail-nickname $AADGrpCatalogaccesspackagemanager --query "id" -o tsv
$AADGrpCatalogaccesspackageassignmentmanagerid = az ad group create --display-name $AADGrpCatalogaccesspackageassignmentmanager --mail-nickname $AADGrpCatalogaccesspackageassignmentmanager --query "id" -o tsv


Write-Host "###################################################################################"
Write-Host "Pausing the Script for 60 Secs for the newly created AAD Group to be populated."
Write-Host "###################################################################################"
Start-Sleep 60

$catalogownerrole = @{
	PrincipalId = "$AADGrpCatalogownerid"
	RoleDefinitionId = "$roleidCatalogowner"
	AppScopeId = "/AccessPackageCatalog/$catalogid"
}

$catalogreaderrole = @{
	PrincipalId = "$AADGrpCatalogreaderid"
	RoleDefinitionId = "$roleidCatalogreader"
	AppScopeId = "/AccessPackageCatalog/$catalogid"
}

$catalogaccesspackagemanagerrole = @{
	PrincipalId = "$AADGrpCatalogaccesspackagemanagerid"
	RoleDefinitionId = "$roleidAccesspackagemanager"
	AppScopeId = "/AccessPackageCatalog/$catalogid"
}

$catalogaccesspackageassignmentmanagerrole = @{
	PrincipalId = "$AADGrpCatalogaccesspackageassignmentmanagerid"
	RoleDefinitionId = "$roleidAccesspackageassignmentmanager"
	AppScopeId = "/AccessPackageCatalog/$catalogid"
}

New-MgRoleManagementEntitlementManagementRoleAssignment -BodyParameter $catalogownerrole
Write-Host "#######################################################################################################################"
Write-Host "AAD Group $AADGrpCatalogowner created successfully and has been added in the Catalog $CatalogName as Catalog Owner."
Write-Host "#######################################################################################################################"

New-MgRoleManagementEntitlementManagementRoleAssignment -BodyParameter $catalogreaderrole
Write-Host "#######################################################################################################################"
Write-Host "AAD Group $AADGrpCatalogreader created successfully and has been added in the Catalog $CatalogName as Catalog Reader."
Write-Host "#######################################################################################################################"

New-MgRoleManagementEntitlementManagementRoleAssignment -BodyParameter $catalogaccesspackagemanagerrole
Write-Host "#######################################################################################################################################################"
Write-Host "AAD Group $AADGrpCatalogaccesspackagemanager created successfully and has been added in the Catalog $CatalogName as Catalog Access Package Manager."
Write-Host "#######################################################################################################################################################"

New-MgRoleManagementEntitlementManagementRoleAssignment -BodyParameter $catalogaccesspackageassignmentmanagerrole
Write-Host "###########################################################################################################################################################################"
Write-Host "AAD Group $AADGrpCatalogaccesspackageassignmentmanager created successfully and has been added in the Catalog $CatalogName as Catalog Access Package Assignment Manager."
Write-Host "###########################################################################################################################################################################"
#>
#############################################
#4. Add AAD Group to the Catalog Resource:-  SCRIPTED IN PowerShell\O365 Cloud Scripts\MSGraph\AccessPackagesProject\BulkGroupAddToCatalog.ps1
#############################################

# az ad group show -g "$AADGroupname" --query "id" -o tsv
<#
function AddGroupToCatalogResourceBulk
{
  param (
    [System.String]$AADGroupname,
    [System.String]$catalogid
  )
  
  $aadgrpid = (Get-MgGroup -Filter ("DisplayName eq '$($AADGroupname)'")).Id

  $accessPackageResource = @{
  "originSystem" = "AadGroup"
  "OriginId" = $aadgrpid
  }

  #https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.beta.identity.governance/new-mgbetaentitlementmanagementaccesspackageresourcerequest?view=graph-powershell-betaa
  New-MgBetaEntitlementManagementAccessPackageResourceRequest -CatalogId $catalogid -RequestType "AdminAdd" -AccessPackageResource $accessPackageResource | Select Id, RequestState | ConvertTo-Json
}

#Auto Adder of groups to Catalog
ForEach($Line in $csvGroup)
{
  AddGroupToCatalogResourceBulk -AADGroupname $Line.AADGroupname -CatalogId $catalogid
}

Write-Host "###################################################################################"
Write-Host "AAD Group $AADGroupname has been added to the Catalog $CatalogName successfully."
Write-Host "###################################################################################"
#>
##################################################
#5. Get ID of the AAD Group as Catalog Resource:-
##################################################

$catalogresourceid = Get-MgBetaEntitlementManagementAccessPackageCatalogAccessPackageResource -AccessPackageCatalogId $catalogid -Filter "DisplayName eq '$AADGroupname'" | Select -ExpandProperty Id

###################################################
#6. Get the Origin ID of the member Resource Role:-
###################################################

$catalogresourceoriginid = Get-MgBetaEntitlementManagementAccessPackageCatalogAccessPackageResourceRole -AccessPackageCatalogId $catalogid -Filter "originSystem eq 'AadGroup' and accessPackageResource/id eq '$catalogresourceid' and DisplayName eq 'Member'" | Select -ExpandProperty OriginId

################################
#7. Create Access Package:-
################################

$accesspkgid = New-MgBetaEntitlementManagementAccessPackage -CatalogId $catalogid -DisplayName $csvFile.AccessPackageName -Description $csvFile.AccessPackageDesc | Select -ExpandProperty Id
Write-Host "#############################################################################################"
Write-Host "Access Package $AccessPackageName has been added to the Catalog $CatalogName successfully."
Write-Host "#############################################################################################"


############################################################
#8. Add Resource Role (Member Role) in the Access Package:-
############################################################

$accessPackageResource = @{
  "id" = $catalogresourceid
  "resourceType" = "Security Group"
  "originId" = $aadgrpid
  "originSystem" = "AadGroup"
  }

$accessPackageResourceRole = @{
  "originId" = $catalogresourceoriginid
  "displayName" = "Member"
  "originSystem" = "AadGroup"
  "accessPackageResource" = $accessPackageResource
  }

$accessPackageResourceScope = @{
  "originId" = $aadgrpid
  "originSystem" = "AadGroup"
  }


New-MgBetaEntitlementManagementAccessPackageResourceRoleScope -AccessPackageId $accesspkgid -AccessPackageResourceRole $accessPackageResourceRole -AccessPackageResourceScope $accessPackageResourceScope | Format-List
Write-Host "#################################################################################################################"
Write-Host "AAD Group $AADGroupname has been added successfully to the Access Package $AccessPackageName with Member Role."
Write-Host "#################################################################################################################"

####################################
#9. Create Access Package Policy:-
####################################

$requestorSettings =@{
  "scopeType" = $csvFile.scopetype
  "acceptRequests" = $csvFile.acceptrequests
  }

$requestApprovalSettings = @{
  "isApprovalRequired" = $csvFile.accesspkgapprovalreq
  "isApprovalRequiredForExtension" = $csvFile.accesspkgapprovalreqext
  "isRequestorJustificationRequired" = $csvFile.accesspkgrequestorjustify
  "approvalMode" = 'NoApproval'
  "approvalStages" = '[]'
  }

New-MgBetaEntitlementManagementAccessPackageAssignmentPolicy -AccessPackageId $accesspkgid -DisplayName $AccessPackagePolicyName -Description $AccessPackagePolicyDesc -DurationInDays $csvFile.duration -RequestorSettings $requestorSettings -RequestApprovalSettings $requestApprovalSettings | Format-List

Write-Host "################################################################################"
Write-Host "Access Package Policy $AccessPackagePolicyName has been created successfully."
Write-Host "################################################################################"