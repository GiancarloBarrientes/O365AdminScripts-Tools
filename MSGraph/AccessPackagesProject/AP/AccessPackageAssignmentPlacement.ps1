<#
.SYNOPSIS
    The purpose of this script is to query user group placements. and will then give you a list of users who are in the group
    which will then give the confirmation (Y/N) to continue to place users as assingments within the accessPKGs. 

    This assignemnt will be used for one access package at a time for now. For control ability

.NOTES
    Author: Giancarlo Barrientes
    Date: April 5th 2024
    Version: 1.0
#>

Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All"
# ACTION ITEMS TO CHANGE WHICH GROUP/AccessPKG YOU WANT TO CHECK/Target. Make sure to spell the name write
$GroupNameDisplayName = "AWS-123456789-Admin"
$TargetAccessPKGDisplayName = "AWS-123456789-Admin"
$UserTimeApplied = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"


# User list that will be user to get users that are in a group
$GroupID = (Get-MGBetaGroup -Filter "DisplayName eq '$($GroupNameDisplayName)'").Id
$UserList = (Get-MGBetaGroupMember -GroupID $GroupID)

# Declaration of variable array to hold the list of UserUPN and UserDisplayName with for loop 
$UserUPNList = @()
foreach($User in $UserList){
    $UserUPNList += $User.AdditionalProperties.userPrincipalName
}



# Show casing the list of individials for script runner to make a choice to continue or not
Write-Host $UserUPNList
$TargetAccessPKGID = (Get-MgBetaEntitlementManagementAccessPackage -filter "DisplayName eq '$($TargetAccessPKGDisplayName)'").Id
Write-Host "Targeting accessPKG: " $TargetAccessPKGID
$TargetAccessPKGPolicyID = (Get-MgBetaEntitlementManagementAccessPackageAssignmentPolicy -filter "AccessPackageID eq '$($TargetAccessPKGID)'").Id
Write-Host "Targeting accessPKGPolicy: "  $TargetAccessPKGPolicyID


# Confirmation that you truly want to do this
do 
{   
    $Confirmation = $true
    #YesNo variable to make sure the user understands who they are adding into the access pkg.
    $YesNo = Read-Host -Prompt "Are you sasitisfied with these individials to be place within the life cycle for AccessPKG: $($TargetAccessPKGDisplayName)`nGood time cross check ID on accessPKG and its correalted policy ID shown above (Y/N): " 
    switch ($YesNo)
    {
        #Start process for assignements of users to access packages
        "Y" {
            Write-host "`n`nStarting assignments of users to policy/life cycle to access package"
            #Loop to go through USER UPN list $UserUPNList
            Foreach($User in $UserList)
            {   # https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.beta.identity.governance/new-mgbetaentitlementmanagementaccesspackageassignmentrequest?view=graph-powershell-beta
                # Requries the following Justification being "Clean Up Start LifeCycle" AdminAdd, Targeting the following -AccessPackageId, -AssignmentPolicyId, -TargetEmail (Using UPN for this)
                New-MGBetaEntitlementManagementAccessPackageAssignmentRequest -Justification "Clean Up Start LifeCycle" -RequestType "AdminAdd" -AccessPackageId $TargetAccessPKGID -AssignmentPolicyId $TargetAccessPKGPolicyID -TargetId $User.Id -StartDate $UserTimeApplied
            }
            $Confirmation = $false
            $UserUPNList = $null
            break
        }

        #Cancling the process ending the script right here
        "N" {
            # N was pressed confirmation set to true to leave do while loop and reset $UserUPNList variable.
            Write-Host "N was chosen Leaving script"
            $Confirmation = $false
            $UserUPNList = $null
            break
        }
        # Wut??? user didnt input the right char or input in general 
        Default {Write-Warning "Invalid Input: Only Enter Y or N"}
    }
} while ($Confirmation)
# END of SCRIPT
