class myOutput {
    $servername
    $sharename
}

$servers=Get-ADComputer -SearchBase "OU=,DC=,DC=" -Filter * | ? name -NotLike *nothishost*

$output=@()

$servers | sort name | select -First 500 | %{
    $servername=$_.name
    if (-not (Test-Connection -ComputerName $_.name -Count 1 -ErrorAction SilentlyContinue)) {
        $myOutputLine=New-Object myOutput
        $myOutputLine.sharename='(offline)'
        $myOutputLine.servername=$servername
        $output+=$myOutputLine
    } else {
        $shares=@()
        $shares+=Get-SmbShare -CimSession $servername | ? Description -ne 'Default share' | ? Name -NotIn ('IPC$','Admin$')
        if ($shares.count -gt 0) {
            $shares | %{
                $myOutputLine=New-Object myOutput
                $myOutputLine.sharename=$_.Name
                $myOutputLine.servername=$servername
                $output+=$myOutputLine
            }
        } else {
            $myOutputLine=New-Object myOutput
            $myOutputLine.sharename='(none)'
            $myOutputLine.servername=$servername
            $output+=$myOutputLine
        }
    }

}

$output | Out-GridView

