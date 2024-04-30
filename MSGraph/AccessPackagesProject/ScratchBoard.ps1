<#
This powershell script is to help with learning how to use ms graph to manipulate/Create Access packages using the Microsoft.Graph.Identity.Management 

#>

# List of the permissions set
# https://learn.microsoft.com/en-us/graph/permissions-reference
Import-Module Microsoft.Graph.Identity.Governance
# Connecting to Azure Graph Tenant
Connect-MGGraph -Scopes EntitlementManagement.ReadWrite.All



function GetAccessPackagesAndAssignmentID {
    $accessPackage = Get-MgBetaEntitlementManagementAccessPackage -DisplayNameEq "AccessPackage01"

    # Get-MgEntitlementManagementAssignment
    # Get-MgBetaEntitlementManagementAccessPackageAssignment
    # Get the access package assignments
    $accessPackageAssignments = Get-MgBetaEntitlementManagementAccessPackageAssignment

    if ($accessPackageAssignments.Count -eq 0) {
        Write-Host "No assignments found for access package '$accessPackageName'."
    } else {
        Write-Host "Access Package Assignments for '$($accessPackage.DisplayName)':"
        foreach ($assignment in $accessPackageAssignments) {
            Write-Host "-------------------------------------------"
            Write-Host "Assignment Id: $($assignment.Id)"
            
            # Check if Target property is not null
            if ($null -ne $assignment.Target ) {
                # Use Format-List to display all properties of Target
                Write-Host "Assignment Target Properties:"
                $assignment.Target | Format-List

                # Access the DisplayName property within Target
                Write-Host "Assignment Name: $($assignment.Target.DisplayName)"
            } else {
                Write-Host "Assignment Name: N/A"
            }
        }
    }
    
}



