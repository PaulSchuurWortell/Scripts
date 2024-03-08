enum returnMode {
    AllDevices
    AllUsers
    Inner
    Full
}

class DeviceUsers{
    [string] $id
    [string] $userId
    [string] $deviceName
    [string] $enrolledDateTime
    [string] $lastSyncDateTime
    [string] $operatingSystem
    [string] $complianceState
    [string] $userPrincipalName
    [string] $userDisplayname   
}

function Find-DeviceUsers {
<#
.SYNOPSIS
    Retrieves devices and users using Graph API and joins the two list in a useable format.
.DESCRIPTION
    Retrieves devices and users using Graph API and joins the two list in a useable format.
    Optionally, a list of users (UPN) and/or a list of devices (displayName aka computername) are provided to filter the results. 

    The returnMode parameter determins the way that the lists are combined. 

.INPUTS
    deviceList:     List of strings representing computernames.
    userList:       List if strings representing userPrincipalNames.
    returnMode:     One of the following options:
    
    AllDevices      returns all selected devices
    AllUsers        returns all selected users
    Inner           returns the 'inner join' of both (only users with devices and devices with users)
    Full            returns the 'full join' of both (includes users without devices and devices without users)


.EXAMPLE
    Find-DeviceUsers -returnMode Full

    Returns a list of all users and all devices, joined on the registered userPrincipalName on the device. All users and devices are returned, even when they can't be joined (devices without owners and users without devices). 

.EXAMPLE
    Find-DeviceUsers -returnMode Inner

    Returns a list of all users and all devices, joined on the registered userPrincipalName on the device. Only users with devices and devices with users are returned. 

.EXAMPLE
    Find-DeviceUsers -userList  -returnMode Inner

    Returns a list of all users and all devices, joined on the registered userPrincipalName on the device. Only users with devices and devices with users are returned. 

.EXAMPLE
    Find-DeviceUsers -userList paul.schuur@wortell.nl,arnold.grooters@wortell.nl -returnMode allUsers | Out-GridView

    Returns a list of all devices for the users in userlist joined on the registered userPrincipalName on the device. The results are presented in a grid.

.EXAMPLE
    Find-DeviceUsers -deviceList LAPTOP001,LAPTOP002 -returnMode allDevices | Out-GridView

    Returns a list of all users for the devices in devicelist joined on the registered userPrincipalName on the device. The results are presented in a grid.
#>
    [CmdletBinding()]
    [OutputType("DeviceUsers")]

    param
    (
        [Parameter (Mandatory=$false)][string[]] $deviceList,
        [Parameter (Mandatory=$false)][string[]] $userList,
        [Parameter (Mandatory=$true)][returnMode] $returnMode
    )

    Begin {
        # Import the Intune PowerShell SDK module
        Import-Module Microsoft.Graph.Intune

        # Connect to the Microsoft Graph with your credentials
        Connect-MSGraph -Quiet 
    } 

    Process {
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
            Full {$DeviceUsers=Join-Object -LeftObject $devices -RightObject $users -On userPrincipalName -JoinType Full }
            Inner {$DeviceUsers=Join-Object -LeftObject $devices -RightObject $users -On userPrincipalName -JoinType Inner }
        }
    } 

    End {
        return $DeviceUsers 
    } 
} 
