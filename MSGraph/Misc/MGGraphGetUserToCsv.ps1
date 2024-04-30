# This script will be used to pull user data that contain a user employee ID 
# This function will be used as a way to get all employee data at once
# Perms required user.read
function Get-AllEmployeeEmailToCsv {
    Connect-MgGraph -TenantId 'a79b435f-7bab-4310-9a04-6202b1536ae0' -Scopes User.Read.All
    # This variable will hold the values DisplayName and EmployeeID, Where there is a value in EmployeeID within the user object
    $EmployeesData = Get-MgBetaUser | Where-Object EmployeeID | Select-Object -Property DisplayName, EmployeeId 
    # Pipes the data that is held within the $employeeID in to a CSV
    $EmployeesData | Export-Csv -Path 'PowerShell\O365 Cloud Scripts\MSGraph\Misc\EmployeeName&ID.CSV' -NoTypeInformation
    # Print out of what is being shot out to the csv
    $EmployeesData
}
#Get-AllEmployeeEmailWithCondToCsv


# Uses all of the users and assignes them a employeeID
# perms required User.ReadWrite.All
# With some exlusion of service account
function UpdateEmployeeIdCorpWide(){
    # Connects to MGGraph
    Connect-MgGraph -TenantId 'a79b435f-7bab-4310-9a04-6202b1536ae0' -Scopes User.ReadWrite.All
    
    # Pull in User data with Displayname, EmployeeId, Object-Id, Email and assigns to a variable
    $EmployeesData = Get-MgBetaUser | Select-Object -Property DisplayName, EmployeeId, Id, Email

    $GroupSVCs = (Get-MgBetaGroup -filter "DisplayName eq 'ServiceAccount'").Id
    $UserAccountsExcludedList = (Get-MGBetaGroupMember -GroupId $GroupSVCs)
    #Remove the IDs that are in a list of services accounts
    foreach($UserAccountsExcludedID in $UserAccountsExcludedList.Id){
        $EmployeesData = $EmployeesData | Where-Object {  $_.Id -ne $UserAccountsExcludedID }
    }
    
    #Function for random # Generator
    function randomEmployeeID(){
        # Define the length of the random number
        $length = 5
        # Generate a random number with 5 characters Uses Ascii for 1-9 
        $randomNumber = -join ((48..57) | Get-Random -Count $length | ForEach-Object { [char]$_ })
        
        # return the random number
        return $randomNumber
    }
    
    foreach($EmployeeData in $EmployeesData){
        # Uses function above to create a random generator for a employeeID
        $EmployeeID = randomEmployeeID
        Update-MgBetaUser -UserId $EmployeeData.ID -EmployeeId $EmployeeID
    }
    
    #Final EmployeeData with removal of service accounts.
    $EmployeesData
}
UpdateEmployeeIdCorpWide

Function Get-HashedPassword {
    Param (
        [Parameter(Mandatory=$true)]
        [System.String]$PasswordString
    )
    #Utilizing .Net libraries mathods and their respective 
    # classes [System.Security.Cryptography.SHA256] and [System.Text.Encoding]
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($PasswordString)
    $hash = $sha256.ComputeHash($bytes)
    $SHA256hashedPassword = [System.Convert]::ToBase64String($hash)

    return $SHA256hashedPassword
}
Get-HashedPassword -PasswordString "Y0urLiZArdH@77y"
