$NewDNSServers = @(
    '1.1.1.1',
    '1.1.1.1')


$Computers = Get-ADComputer -Filter { OperatingSystem -Like '*Windows Server*'}
Foreach($Computer in $Computers) {

Write-Host "------------------------------------"
$Computer.Name
$i = 0
$NICs = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $Computer.Name | Where {($_.DNSServerSearchOrder -like "1.1.1.1") -or ($_.DNSServerSearchOrder -like "1.1.1.1") -and ($_.DHCPEnabled -eq $False)}
Foreach($NIC in $NICs) {

$i++
$path = ".\DNS_" + $Computer.name + "_NIC" + $i + ".txt"
Write-host "Netwerkkaart $i"

$NIC | Select-Object -Property [a-z]* -ExcludeProperty IPX*,WINS*


$NIC | Select-Object -Property [a-z]* -ExcludeProperty IPX*,WINS* | Out-File -FilePath $path


$NIC.SetDNSServerSearchOrder($NewDNSServers)
#$NIC.SetDynamicDNSRegistration("TRUE")

}

}
