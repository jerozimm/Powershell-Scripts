function Install-ClickOnce {
[CmdletBinding()] 
Param(
    $Manifest = "https://cmdletpswmodule.blob.core.windows.net/exopsmodule/Microsoft.Online.CSE.PSModule.Client.application",
    #AssertApplicationRequirements
    $ElevatePermissions = $true
)
    Try { 
        Add-Type -AssemblyName System.Deployment
        
        Write-Verbose "Start installation of ClockOnce Application $Manifest "

        $RemoteURI = [URI]::New( $Manifest , [UriKind]::Absolute)
        if (-not  $Manifest)
        {
            throw "Invalid ConnectionUri parameter '$ConnectionUri'"
        }

        $HostingManager = New-Object System.Deployment.Application.InPlaceHostingManager -ArgumentList $RemoteURI , $False
    
        #register an event to trigger custom event (yep, its a hack) 
        Register-ObjectEvent -InputObject $HostingManager -EventName GetManifestCompleted -Action { 
            new-event -SourceIdentifier "ManifestDownloadComplete"
        } | Out-Null
        #register an event to trigger custom event (yep, its a hack) 
        Register-ObjectEvent -InputObject $HostingManager -EventName DownloadApplicationCompleted -Action { 
            new-event -SourceIdentifier "DownloadApplicationCompleted"
        } | Out-Null

        #get the Manifest
        $HostingManager.GetManifestAsync()

        #Waitfor up to 5s for our custom event
        $event = Wait-Event -SourceIdentifier "ManifestDownloadComplete" -Timeout 5
        if ($event ) {
            $event | Remove-Event
            Write-Verbose "ClickOnce Manifest Download Completed"

            $HostingManager.AssertApplicationRequirements($ElevatePermissions)
            #todo :: can this fail ?
            
            #Download Application 
            $HostingManager.DownloadApplicationAsync()
            #register and wait for completion event 
            # $HostingManager.DownloadApplicationCompleted 
            $event = Wait-Event -SourceIdentifier "DownloadApplicationCompleted" -Timeout 15
            if ($event ) {
                $event | Remove-Event
                Write-Verbose "ClickOnce Application Download Completed"
            } else {
                Write-error "ClickOnce Application Download did not complete in time (15s)"
            }
        } else {
           Write-error "ClickOnce Manifest Download did not complete in time (5s)"
        }

        #Clean Up 
    } finally {
        #get rid of our eventhandlers
        Get-EventSubscriber|? {$_.SourceObject.ToString() -eq 'System.Deployment.Application.InPlaceHostingManager'} | Unregister-Event
    }
}


<# Simple Install Check 
#>
function Get-ClickOnce {
[CmdletBinding()]  
Param(
    $ApplicationName = "Microsoft Exchange Online Powershell Module"
)
    $InstalledApplicationNotMSI = Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall | foreach-object {Get-ItemProperty $_.PsPath}
    return $InstalledApplicationNotMSI | ? { $_.displayname -match $ApplicationName } | Select-Object -First 1
}

Function Test-ClickOnce {
[CmdletBinding()] 
Param(
    $ApplicationName = "Microsoft Exchange Online Powershell Module"
)
    return ( (Get-ClickOnce -ApplicationName $ApplicationName) -ne $null) 
}


Function Load-ExchangeMFAModule { 
[CmdletBinding()] 
Param ()
    $Modules = @(Get-ChildItem -Path "$($env:LOCALAPPDATA)\Apps\2.0" -Filter "Microsoft.Exchange.Management.ExoPowershellModule.manifest" -Recurse )
    if ($Modules.Count -ne 1 ) {
        throw "No or Multiple Modules found : Count = $($Modules.Count )"  
    }  else {
        $ModuleName =  Join-path $Modules[0].Directory.FullName "Microsoft.Exchange.Management.ExoPowershellModule.dll"
        Write-Verbose "Start Importing MFA Module"
        Import-Module -FullyQualifiedName $ModuleName  -Force 

        $ScriptName =  Join-path $Modules[0].Directory.FullName "CreateExoPSSession.ps1"
        if (Test-Path $ScriptName) {
            return $ScriptName
<# 
            # Load the script to add the additional commandlets (Connect-EXOPSSession) 
            # DotSourcing does not work from inside a function (. $ScriptName) 
            #Therefore load the script as a dynamic module instead 
 
            $content = Get-Content -Path $ScriptName -Raw -ErrorAction Stop 
            #BugBug >> $PSScriptRoot is Blank :-( 
<# 
            $PipeLine = $Host.Runspace.CreatePipeline() 
            $PipeLine.Commands.AddScript(". $scriptName") 
            $r = $PipeLine.Invoke() 
#Err : Pipelines cannot be run concurrently. 
 
            $scriptBlock = [scriptblock]::Create($content) 
            New-Module -ScriptBlock $scriptBlock -Name "Microsoft.Exchange.Management.CreateExoPSSession.ps1" -ReturnResult -ErrorAction SilentlyContinue 
#>

        } else {
            throw "Script not found"
            return $null
        }
    }
}

$AzureAd = (Get-Module -ListAvailable -Name azureAD*).name
if (Get-Module -ListAvailable -Name azureAD*) {
    Write-Host "$AzureAd has been installed" -ForegroundColor Green
} else {
    Write-Host "Installing AzureAD Module"
    Install-Module AzureADPreview
}

if ((Test-ClickOnce -ApplicationName "Microsoft Exchange Online Powershell Module" ) -eq $false)  {
   Install-ClickOnce -Manifest "https://cmdletpswmodule.blob.core.windows.net/exopsmodule/Microsoft.Online.CSE.PSModule.Client.application"
}
#Load the Module
$script = Load-ExchangeMFAModule -Verbose
#Dot Source the associated script
. $Script
Connect-AzureAD
Connect-EXOPSSession