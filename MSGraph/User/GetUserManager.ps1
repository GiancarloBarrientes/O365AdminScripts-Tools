# This script is designed to pull off manager off of a user account

#Authentication through non defualt entra app MG graph app
Connect-MgGraph  -TenantId a79b435f-7bab-4310-9a04-6202b1536ae0 -Scopes  "User.Read.All"


#Intialize TeamList array to hold multiple values
$TeamList = @()

# Employee list
$employeeEmailList = @(
    "NestorW@zsbf1.onmicrosoft.com",
    "PattiF@zsbf1.onmicrosoft.com",
    "PradeepG@zsbf1.onmicrosoft.com",
    "AdeleV@zsbf1.onmicrosoft.com"
)

# Loop to create CSV
Foreach($Employee in $employeeEmailList)
{
    #Employee you want to find the manager for. 
    $employeeID = (Get-MGbetaUser -Filter "UserPrincipalName eq '$($Employee)'").id
    
    #Manager info retreival
    $ManagerID = Get-MgUserManager -UserId $employeeID
    $Manager = (Get-MGUser -UserId $ManagerID.id).Mail
    
    #Placement of user email and thier respective manager email
    $TeamList +=  [PSCustomObject]@{Employee = $Employee; Manager = $Manager}
}
# Exportation of CSV of Employee and Manager
$TeamList | Export-Csv -Path "PowerShell\O365 Cloud Scripts\MSGraph\User\UserAudit.csv" -NoTypeInformation