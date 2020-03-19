$Mailboxlist = Import-Csv .\Fullaccessgroups.csv
foreach ($Mailbox in $Mailboxlist) {
#Group with permissions to shared mailbox
$Group = $Mailbox.User
#Shared mailbox
$Identity = $Mailbox.Identity
#Get Group ID
$ID = (Get-AzureADGroup -Filter "DisplayName eq '$Group'").ObjectId
#Get groupmembers
Get-AzureADGroupMember -ObjectId $ID | foreach-Object { 
#Write-Host "Added " $_.UserPrincipalName" To " $Identity
#Add Full access mailbox permission
Add-MailboxPermission -Identity $Identity –AccessRights FullAccess –user $_.UserPrincipalName
}
}