<#The point of this script is to show case how to configure the Access Package with the following in order 
1. Adds the catalog to a access package
2. Applying a group/groups to be assigned to a user account after getting approval
2. line Adding Policy (Approvers, Who can request, Num of Stages, ETC) #>


#Import-Module Microsoft.Graph.Beta.Identity.Governance

Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All"


$csvFile = Import-Csv  "/Users/giancarlo/Desktop/PowershellScripts/MSGraph/AccessPackagesProject/AP/APPolicyData.csv"

foreach($line in $csvFile){
    # Variables declaration for creating
    #$AADGroupname = "U.S. Sales"
    #$AADGroupnameResource = "Cloud Group1"
    $aadgrpid = (Get-MgBetaGroup -Filter ("DisplayName eq '$($line.APGroupNameAssignment1)'")).Id
    $Catalogid = $line.CatalogID

    $accesspkgid = Get-MgBetaEntitlementManagementAccessPackage -Filter "Displayname eq '$($line.APDisplayName)'" | Select-Object -ExpandProperty Id

    Write-Host "#############################################################################################"
    Write-Host "Access Package $AccessPackageName has been added to the Catalog $CatalogName successfully."
    Write-Host "#############################################################################################"


    ############################################################
    #8. Add Resource Role (Member Role) in the Access Package:- Where we configure the group we want assigned into the access package as far as a member of the group.
    ############################################################

    #Get ID of the AAD Group as Catalog Resource:-
    $catalogresourceid = Get-MgBetaEntitlementManagementAccessPackageCatalogAccessPackageResource -AccessPackageCatalogId $catalogid | Where-Object DisplayName -Like $line.APGroupNameAssignment1| Select-Object -ExpandProperty Id
    $catalogresourceoriginid = Get-MgBetaEntitlementManagementAccessPackageCatalogAccessPackageResourceRole -AccessPackageCatalogId $catalogid -Filter "originSystem eq 'AadGroup' and accessPackageResource/id eq '$catalogresourceid' and DisplayName eq 'Member'" | Select -ExpandProperty OriginId

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
    Write-Host "AAD Group $AADGroupnameResource has been added successfully to the Access Package $AccessPackageName with Member Role."
    Write-Host "#################################################################################################################"


    ### START WITH POLICY ASSIGNMENT PORTION OF SCRIPT HERE ####
    #https://learn.microsoft.com/en-us/graph/api/resources/requestorsettings?view=graph-rest-beta
    #https://learn.microsoft.com/en-us/graph/api/resources/groupmembers?view=graph-rest-beta
    #This is an Array constructor, that holds 2 hash tables values groupMembers.
    
    #Requestor data here which will come from the line of the csv
    $allowed3GroupRequestors = @(
    @{
      #For single users "@odata.type" = '#microsoft.graph.singleUser'
      "@odata.type" = '#microsoft.graph.groupMembers'
      "isBackup" = $false
      "id"= $line.AllowedGroupRequestID1 #'bef2a5cf-a5f3-4db2-b3a1-c910e3e6808d'
      "description" = $line.AllowedGroupRequestName1
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
      "isBackup" = $false
      "id"= $line.AllowedGroupRequestID1 #'bef2a5cf-a5f3-4db2-b3a1-c910e3e6808d'
      "description" = $line.AllowedGroupRequestName1
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

    
    ### The approval sections of the script this will be for held variables. Conditional statements will use these based on value in a csv cell
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
    
    <#
    MULTI STAGE APPROVALS
    Something to research on how to do this. Making a guess on how request ApprovalTwoStageSetting is
    $ApprovalStageOneSetting = @{
      "@odata.type" = "#microsoft.graph.approvalStage"
      "approvalStageTimeOutInDays" = 14
      "isApproverJustificationRequired" = $true
      "escalationTimeInMinutes" = $null #not valid if 
      #https://learn.microsoft.com/en-us/graph/api/resources/singleuser?view=graph-rest-beta
      "primaryApprovers" = $ApprovalSingleUsers
      "isEscalationEnabled" = $false
      #"escalationApprovers" = #"@odata.type": "microsoft.graph.singleUser"
    }
    
    $ApprovalStageTwoSetting = @{
      "@odata.type" = "#microsoft.graph.approvalStage"
      "isApproverJustificationRequired" = $true
      "escalationTimeInMinutes" = $null #not valid if 
      #https://learn.microsoft.com/en-us/graph/api/resources/singleuser?view=graph-rest-beta
      "primaryApprovers" = $ApprovalSingleUsers
      "isEscalationEnabled" = $false
    }
    #https://learn.microsoft.com/en-us/graph/api/resources/approvalsettings?view=graph-rest-1.0
    $requestApprovalOneStageSetting = @{
      "isApprovalRequired" = $true
      "isApprovalRequiredForExtension" = $false
      "isRequestorJustificationRequired"= $false
      "approvalMode"= 'Serial' # Options include SingleStage, Serial, Parallel, NoApproval
      "approvalStages" = @($ApprovalStageOneSetting)
    }
    
    $requestApprovalTwoStageSetting = @{
      "isApprovalRequired" = $true
      "isApprovalRequiredForExtension" = $false
      "isRequestorJustificationRequired"= $false
      "approvalMode"= 'Serial' # Options include SingleStage, Serial, Parallel, NoApproval
      "approvalStages" = @($ApprovalStageOneSetting, $ApprovalStageTwoSetting)
    }
    #>


    $requestApprovalOneStageSetting = @{
      "isApprovalRequired" = $true
      "isApprovalRequiredForExtension" = $false
      "isRequestorJustificationRequired"= $false
      "approvalMode"= 'SingleStage' # Options include SingleStage, Serial, Parallel, NoApproval
      "approvalStages" = @($approvalStageSettings)
    }
  <#NOTES:
  With condidtional statements we are able to choose some pre built settings. For the sake of simplicity only making single stage.
  #>
  #https://learn.microsoft.com/en-us/powershell/module/Microsoft.Graph.Beta.Identity.Governance/New-MgBetaEntitlementManagementAccessPackageAssignmentPolicy?view=graph-powershell-beta
  New-MgBetaEntitlementManagementAccessPackageAssignmentPolicy -AccessPackageId $accesspkgid -DisplayName "TestPolicyFinal" -Description "Testing policy making with powershell" -durationInDays 365 -RequestorSettings $requestorSettings -RequestApprovalSettings $requestApprovalOneStageSetting
}