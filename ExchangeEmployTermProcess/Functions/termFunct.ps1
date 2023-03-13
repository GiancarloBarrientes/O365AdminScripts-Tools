function AutoConvert2SharedInbox([System.Object]$csv) 
{
    
    Write-host "Starting Converting reg to shared script"
    foreach($line in $csv)
    {   
       

        #Converting of inboxes
        Write-host $line.TermEmail "Working on converting to shared inbox"
        Set-Mailbox -Identity $line.TermEmail -Type Shared
        if($?)
        {
            Write-host $line.TermEmail ": successfully converted shared inbox"
        }
        else 
        {
           Write-host $line.TermEmail ": Something wrong happened please check the FirstLast Collunm on the script"
        }
        
        #disabling of login
        Write-host $line.TermEmail": Disabling login"
        Set-MsolUser -UserPrincipalName $line.TermEmail -BlockCredential $true
        if($?)
        {
            Write-host $line.TermEmail ": successfully blocked login to the shared inbox"
        }
        else 
        {
           Write-host $line.TermEmail ": Something wrong happened please check the FirstLast Collunm on the script"
        }
    }
}

function AutoRemoveM365License([System.Object]$csv)
{
    
    Write-host "Starting Removal of M365 License process"
    foreach($line in $csv)
    {
        #Run Get-MsolAccountsSKu to find tenant licenses names
        $LicenseE1 = "tenant:e1License"
        #Copy and paste line 47-55 if you want to delete more licesnces. 
        Set-MsolUserLicense -UserPrincipalName $line.TermEmail -RemoveLicenses $LicenseE1
        if($?)
        {
            Write-host $line.TermEmail ": is finsihed removing license x"
        }
        else 
        {
           Write-host $line.TermEmail ": License has already been revoked in regards to e1 license"
        }

        
    }
}

function AutoOOOwCSV ([System.Object]$csv)
{
    Foreach ($line in $csv)
    {
        Set-MailboxAutoReplyConfiguration $line.TermEmail -AutoReplyState Scheduled  -ExternalMessage $line.OOOConcat -InternalMessage $line.OOOConcat
        if($?)
        {
            Write-host $line.FirstLast " ooo msg has been set!"
        }
        else
        {
            Write-host $line.FirstLast " ooo msg has not been set take a look at FirstLast collumn in csv!"
        }
    }
}

function AutoDelegateManager([System.Object]$csv)
{
    Write-host ""
    Write-host "Moving to Mailbox Delegations"
    Write-host ""
    foreach($line in $csv)
    {
        Write-host $line.ManagerEmail
        Add-MailboxPermission -Identity $line.TermEmail -User $line.ManagerEmail -AccessRights FullAccess -InheritanceType All
        if($?)
        {
            Write-host $line.FirstLast " Delegation has been set"
        }
        else
        {
            Write-host $line.FirstLast "Delegation has not been set take a look at ManagersEmail or FirstLast collumn in csv!"
        }
    }
}
