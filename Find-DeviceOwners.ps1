enum returnMode {
    AllDevices
    AllUsers
    Both
}

function Find-DeviceOwners {
    param
    (
        [Parameter (Mandatory=$false)][string[]] $deviceList,
        [Parameter (Mandatory=$false)][string[]] $userList,
        [Parameter (Mandatory=$true)][returnMode] $returnMode
    )

    try {
    
        # Import the Intune PowerShell SDK module
        Import-Module Microsoft.Graph.Intune

        # Connect to the Microsoft Graph with your credentials
        Connect-MSGraph -Quiet 


        # Query the Intune managed devices using the Graph API
        $devices = @()
        $nextLink = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"
        do {
            $devicesResponse = Invoke-MSGraphRequest -HttpMethod GET -Url  $nextLink 
            $devices += $devicesResponse.value | select id, userId,deviceName,enrolledDateTime,lastSyncDateTime,operatingSystem,complianceState,userPrincipalName,userDisplayname
            $nextLink = $devicesResponse."@odata.nextLink"
        } while ($nextLink)


        # Query the Intune users using the Graph API
        $users=@()
        $nextLink = "https://graph.microsoft.com/v1.0/users" 
        do {
            $usersResponse = Invoke-MSGraphRequest -HttpMethod GET -Url $nextLink
            $users += $usersResponse.value | ? userPrincipalName | select displayName,mail,userPrincipalName
            $nextLink = $usersResponse."@odata.nextLink"
        } while ($nextLink)


        if ($userList.Count -gt 0) { $users=$users| ? userPrincipalName -In $userList }
        if ($deviceList.Count -gt 0) { $devices=$devices| ? deviceName -In $deviceList }
 
        switch ($returnMode) {
            AllDevices {$DeviceUsers=Join-Object -LeftObject $devices -RightObject $users -On userPrincipalName -JoinType Left}
            AllUsers {$DeviceUsers=Join-Object -LeftObject $devices -RightObject $users -On userPrincipalName -JoinType Right}
            Both {$DeviceUsers=Join-Object -LeftObject $devices -RightObject $users -On userPrincipalName -JoinType Full}
        }
 
    

        return $DeviceUsers 
    } 
    catch {
        Write-host -f red "Encountered Error:"$_.Exception.Message
        #$Error[0]
    }
}