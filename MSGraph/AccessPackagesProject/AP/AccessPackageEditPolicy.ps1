#This script will be used to Edit a policy that a AccessPackage holds

# Importation of modules that will provide the script the commands it needs
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Beta.Identity.Governance

# Connect to mg-graph requiring the entitlement managment
Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All"

<#
ITEMS NEEDED
ACCESS PKG ID
ACCESS PKG POLICY ID
#>


Import-Module Microsoft.Graph.Beta.Identity.Governance
$csvFile = Import-Csv  "/PathTo/MSGraph/AccessPackagesProject/AP/APPolicyDataEdit.csv"
#$

foreach ($Line in $csvFile)
{
    # Holds AccessPKG ID
    $accesspkgid = Get-MgBetaEntitlementManagementAccessPackage -Filter  "Displayname eq '$($line.APDisplayName)'" | Select-Object -ExpandProperty Id
    #Hold access pkg policy ID
    # https://learn.microsoft.com/en-us/powershell/module/Microsoft.Graph.Beta.Identity.Governance/Get-MgBetaEntitlementManagementAccessPackageAssignmentPolicy?view=graph-powershell-beta
    # This only works with one policy being assigned in a AccessPackage
    $accesspkgpolicyid = (Get-MgBetaEntitlementManagementAccessPackageAssignmentPolicy -filter "AccessPackageID eq '$($accesspkgid)'").Id

    ### START WITH POLICY ASSIGNMENT PORTION OF SCRIPT HERE ####
    #https://learn.microsoft.com/en-us/graph/api/resources/requestorsettings?view=graph-rest-beta
    #https://learn.microsoft.com/en-us/graph/api/resources/groupmembers?view=graph-rest-beta
    #This is an Array constructor, that holds 2 hash tables values groupMembers. 
    #Requestor data here which will come from the line of the csv
    $allowed3GroupRequestors = @(
        @{
        #For single users "@odata.type" = '#microsoft.graph.singleUser'
        "@odata.type" = '#microsoft.graph.groupMembers'
        "id"= $line.AllowedGroupRequestID1 #'bef2a5cf-a5f3-4db2-b3a1-c910e3e6808d'
        "description" = $line.AllowedGroupRequestName1
        "isBackup" = $false
        }
        
        @{
        "@odata.type" = '#microsoft.graph.groupMembers'
        "id"= $line.AllowedGroupRequestID2
        "description" = $line.AllowedGroupRequestName2
        "isBackup" = $false
        }

        @{
        "@odata.type" = '#microsoft.graph.groupMembers'
        "id"= $line.AllowedGroupRequestID3
        "description" = $line.AllowedGroupRequestName3
        "isBackup" = $false
        }
    )
    
    $allowed2GroupRequestors = @(
        @{
        #For single users "@odata.type" = '#microsoft.graph.singleUser'
        "@odata.type" = '#microsoft.graph.groupMembers'
        "id"= $line.AllowedGroupRequestID1 #'bef2a5cf-a5f3-4db2-b3a1-c910e3e6808d'
        "description" = $line.AllowedGroupRequestName1
        "isBackup" = $false
        }
        
        @{
        "@odata.type" = '#microsoft.graph.groupMembers'
        "id"= $line.AllowedGroupRequestID2
        "description" = $line.AllowedGroupRequestName2
        "isBackup" = $false
        }
    )
    
    $allowed1GroupRequestors = @(@{
        #For single users "@odata.type" = '#microsoft.graph.singleUser'
        "@odata.type" = '#microsoft.graph.groupMembers'
        "isBackup" = $false
        "id"= $line.AllowedGroupRequestID1 #'bef2a5cf-a5f3-4db2-b3a1-c910e3e6808d'
        "description" = $line.AllowedGroupRequestName1
    })
        
    ###LOGIC start for the end command choosing how many group requestors
    if ($line.AllowedGroupRequestID3 -and $line.AllowedGroupRequestID2)
    {
    $requestorSettings = @{
        "scopeType" = 'SpecificDirectorySubjects'
        "acceptRequests" = $true
        "allowedRequestors" = $allowed3GroupRequestors
    }
    Write-Host "3 Value for Requestors. allowedRequestors = allowed3GroupRequestors"
    }
    elseif ($line.AllowedGroupRequestID2 -and -not $line.AllowedGroupRequestID3)
    {
    $requestorSettings = @{
        "scopeType" = 'SpecificDirectorySubjects'
        "acceptRequests" = $true
        "allowedRequestors" = $allowed2GroupRequestors
    }
    Write-Host "2 Value for Requestors. allowedRequestors = allowed2GroupRequestors"
    }
    elseif ($line.AllowedGroupRequestID1 -and -not ($line.AllowedGroupRequestID2 -or $line.AllowedGroupRequestID3))
    {
    $requestorSettings = @{
        "scopeType" = 'SpecificDirectorySubjects'
        "acceptRequests" = $true
        "allowedRequestors" = $allowed1GroupRequestors
    }
    Write-Host "1 Value for Requestors. allowedRequestors = allowed1GroupRequestors"
    }
    else
    {
    # Handle the case when none of the conditions are met
    $requestorSettings = @{
        "scopeType" = 'DefaultScopeType'
        "acceptRequests" = $false
        "allowedRequestors" = @()
    }
    Write-Host "No Value for Requestors. acceptRequest set to False"
    }
   
    $ApprovalSingleUsers =@(
    @{
      "@odata.type" = "#microsoft.graph.singleUser" 
      "id" = $line.ApprovalFirstUserID #"be1728d8-d753-408c-b82c-77ea5cbbee97" #(Get-MgUser -Filter "DisplayName eq 'giancarlo barrientes'").Id
      "description" = $line.ApprovalFirstUserName
      "isBackup" = $false
    }
    )

    $ApprovalDoubleUsers =@(
    @{
    "@odata.type" = "#microsoft.graph.singleUser"
    "id" = $line.ApprovalFirstUserID #(Get-MgUser -Filter "DisplayName eq 'giancarlo barrientes'").Id
    "description" = $line.ApprovalFirstUserName
    "isBackup" = $false
    }
    
    @{
    "@odata.type" = "#microsoft.graph.singleUser"
    "id" = $line.ApprovalSecondUserID #(Get-MgUser -Filter "DisplayName eq 'Nestor Wilke'").Id
    "description" = $line.ApprovalSecondUserName
    "isBackup" = $false
    }
    )
    
    if ($line.ApprovalFirstUserID -and -not $line.ApprovalSecondUserID)
    {
    $approvalStageSettings = @{
        "@odata.type" = '#microsoft.graph.approvalStage'
        "approvalStageTimeOutInDays" = 14
        "isApproverJustificationRequired" = $true
        "escalationTimeInMinutes" = $null
        "primaryApprovers" = $ApprovalSingleUsers
        "isEscalationEnabled" = $false
    }
    }
    elseif ($line.ApprovalFirstUserID -and $line.ApprovalSecondUserID)
    {
    $approvalStageSettings = @{
        "@odata.type" = '#microsoft.graph.approvalStage'
        "approvalStageTimeOutInDays" = 14
        "isApproverJustificationRequired" = $true
        "escalationTimeInMinutes" = $null
        "primaryApprovers" = $ApprovalDoubleUsers
        "isEscalationEnabled" = $false
    }
    }
    else
    {
    # Handle the case when none of the conditions are met
    $approvalStageSettings = @{
        "@odata.type" = '#microsoft.graph.approvalStage'
        "approvalStageTimeOutInDays" = 14
        "isApproverJustificationRequired" = $true
        "escalationTimeInMinutes" = $null
        "primaryApprovers" = @()
        "isEscalationEnabled" = $false
    }
    }

    $requestApprovalOneStageSetting = @{
    "isApprovalRequired" = $true
    "isApprovalRequiredForExtension" = $false
    "isRequestorJustificationRequired"= $false
    "approvalMode"= 'SingleStage' # Options include SingleStage, Serial, Parallel, NoApproval
    "approvalStages" = @($approvalStageSettings)
    }

    #Main commandlet that controls the policy change
    Set-MgBetaEntitlementManagementAccessPackageAssignmentPolicy -AccessPackageAssignmentPolicyId $accesspkgpolicyid -DisplayName "TestPolicyFinal" -Description "Testing policy making with powershell" -durationInDays 365 -RequestorSettings $requestorSettings -RequestApprovalSettings $requestApprovalOneStageSetting
}