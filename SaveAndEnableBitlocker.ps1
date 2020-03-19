<#
AzureAD
Add-BitLockerKeyProtector -MountPoint "C:" -RecoveryPasswordProtector
$BLV = Get-BitLockerVolume -MountPoint "C:"
BackupToAAD-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $BLV.KeyProtector[0].KeyProtectorId

TPM + PIN
$SecureString = ConvertTo-SecureString "123456" -AsPlainText -Force
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -Pin $SecureString -TPMandPinProtector
#>

Start-Transcript -Path "C:\bitlocker.txt" -Append -Force
Add-BitLockerKeyProtector -MountPoint "C:" -RecoveryPasswordProtector
$BLV = Get-BitLockerVolume -MountPoint "C:"
Backup-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $BLV.KeyProtector[0].KeyProtectorId
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -TpmProtector
Stop-Transcript
