Import-Module ActiveDirectory               ##create a new user that will be used as temp admin to execute remote code as current server admins have token size issues
New-ADUser -Name "Temp Server admin" -GivenName "TempServerAdmin" -Surname "TempServerAdmin" -SamAccountName "TempServerAdmin" -UserPrincipalName "TempServerAdmin@enterprise.com" -Path "OU=Managers,DC=enterprise,DC=com" -AccountPassword(Read-Host -AsSecureString "Input Password") -Enabled $true
Connect-VIServer -Server 10.1.50.20 -User domain\adminPowerCLIuser -Password 'yourpassword'
get-vm | Where-Object {$_.Guest.OSFullName -Match "windows" -and $_.GuestId -Match "windows" -and $_.PowerState -eq 'PoweredOn'} | Select-Object Name | Format-Table -AutoSize > host-list.txt##get the list of Windows hosts
[System.Collections.Generic.List[System.Object]]$list = Get-Content -Path 'host-list.txt'
Clear-content -Path 'host-list.txt'
for ($i = 0; $i -lt 3; $i++) {##remove blank or null and title
    $list.RemoveAt(0)
}
$newList = @()
$newList = $list.Clone()
for ($i = 0; $i -lt $newList.Length; $i++) {##remove empty spaces on host names
    $newList[$i] = $newList[$i].Trim()
}
for ($i = 0; $i -lt $newList.Length; $i++) {##saving a report with the list of servers to check
    Add-Content -Path "host-list.txt" $newList[$i]
}
$newList = Get-Content -Path "host-list.txt"
$newList.Length
for($j = 0; $j -lt $newList.Length; $j++){##generating reports, one for apps installed on each server and one text file for hosts not reachable or with access denied per no http connection rule on firewall
    $hname = '\\' + $newList[$j]
    $hname
    $user='domain\temp-account-used-as-server-admin'; $pass='that-one-password'             ##temp admin
    $Credential = New-Object System.Management.Automation.PSCredential $user,(ConvertTo-SecureString $pass -AsPlainText -Force)
    psexec $hname net localgroup administrators teleflex\ServerAdminTest /add ##adding temp admin on each host
    Invoke-Command -ComputerName $newList[$j] -Credential $Credential -ScriptBlock{
        $installedApps = Get-WmiObject -Class Win32_Product
        $path = Test-Path -Path "C:\Scripts\"
        if ($path -eq $true) {                                              ##creating a report of apps installed on each host
            Add-content -Path "C:\Scripts\installedApps.csv" $installedApps
            }
        else {
            New-Item -Path "c:\" -Name "Scripts" -ItemType "directory"
            Add-content -Path "C:\Scripts\installedApps.csv" $installedApps
            }
        }
    psexec $hname net localgroup administrators teleflex\ServerAdminTest /delete ##removing temp admin on each host
    $hname = $hname + '\C$\Scripts\installedApps.csv'
    $path = Test-Path -Path $hname -PathType Leaf
    if ($path) {                                                                            ##creating a report adding each host report
        $partialReport = Get-Content $hname
        Add-Content -Path "\\net-util\c$\report\installedApps.csv" $partialReport
    }
    else {                                                                                  ##creating a list of 
        Add-Content -Path '\\net-util\c$\report\ErrorLog.txt' $newList[$j]
    }
}
Remove-ADUser -Identity TempServerAdmin
