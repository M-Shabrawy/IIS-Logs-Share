If (-NOT(is-admin))
 {    
  Echo "This script needs to be run As Admin"
  Break
 }

function is-admin
 {
 # Returns true/false
   ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
 }
 
 function Get-OSVersion{
    (Get-WMIObject win32_operatingsystem).Name.Split('|')[0]
 }

function Set-FolderPermission{
    param(
        [string]$folderPath = 'C:\inetpub\logs\LogFiles',
        [string]$user = "lr"
    )
    $Rights = "Read, ReadAndExecute, ListDirectory"
    $InheritSettings = "Containerinherit, ObjectInherit"
    $PropogationSettings = "none"
    $RuleType = "Allow"

    $acl = Get-Acl $folderPath
    $perm = $user, $Rights, $InheritSettings, $PropogationSettings, $RuleType
    $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $perm
    $acl.SetAccessRule($rule)
    $acl | Set-Acl -Path $folderPath
}

function Create-IISShare{
    param(
        [string]$logsFilePath = 'C:\inetpub\logs\LogFiles',
        [string]$User = 'lr',
        [string]$name
    )
    $Share = New-SmbShare -Path $logsFilePath -Name $name  -ReadAccess $User
    $Share.Name
}


[string]$OutputFile = "$env:USERPROFILE\Desktop\$($env:ComputerName).txt"

if((Get-WindowsFeature -Name Web-Server).Installed){
    If((Get-Service -Name w3svc).Status -eq 'Running'){
        Import-Module WebAdministration
        $Sites = Get-ChildItem iis:\\Sites
        Foreach($Site in $Sites){
            if($Site.State -eq 'Started'){
                $logFolder = "$($Site.logFile.directory)\w3svc$($Site.id)".replace("%SystemDrive%",$env:SystemDrive)
                if(!(Test-Path $logFolder)){
                    New-Item -Path $logFolder -ItemType Directory -Force
                }
                $shareName = "w3svc$($Site.id)"
                Set-FolderPermission -folderPath $logFolder
                $sName = Create-IISShare -logsFilePath $logFolder -User 'lr' -name $shareName
                "$($env:ComputerName),$($Site.Name),\\$($env:ComputerName)\$($sName)"| Out-File -FilePath $OutputFile -Append
            }
        }
    }
    else{
        "IIS Installed but service stopped" | sc $OutputFile -Force
    }
}
else{
    "IIS Not Installed" | sc $OutputFile -Force
}