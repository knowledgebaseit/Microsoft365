[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Check of NuGet is installed.
if (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue) {
    Write-Host "NuGet Already Installed"
} else {
    try {
        Install-PackageProvider -Name 'Nuget' -Confirm:$False -Force
    }
    catch [Exception] {
        $_.message 
        exit
    }
}

#Check of Evergreen is installed.
if (Get-Module -ListAvailable -Name Evergreen) {
    Write-Host "Evergreen Already Installed"
} else {
    try {
        Install-Module -Name Evergreen -Repository PSGallery -Confirm:$False -Force  
    }
    catch [Exception] {
        $_.message 
        exit
    }
}

#Check of IntuneWin32App is installed.
if (Get-Module -ListAvailable -Name IntuneWin32App) {
    Write-Host "IntuneWin32App Already Installed"
} else {
    try {
        Install-Module -Name IntuneWin32App -Repository PSGallery -Confirm:$False -Force  
    }
    catch [Exception] {
        $_.message 
        exit
    }
}

#Check of Microsoft.Graph.Users is installed.
if (Get-Module -ListAvailable -Name Microsoft.Graph.Users) {
    Write-Host "Microsoft.Graph.Users Already Installed"
} else {
    try {
        Install-Module -Name Microsoft.Graph.Users -Repository PSGallery -Confirm:$False -Force  
    }
    catch [Exception] {
        $_.message 
        exit
    }
}

#Check of Microsoft.Graph.Intune is installed.
if (Get-Module -ListAvailable -Name Microsoft.Graph.Intune) {
    Write-Host "Microsoft.Graph.Intune Already Installed"
} else {
    try {
        Install-Module -Name Microsoft.Graph.Intune -Repository PSGallery -Confirm:$False -Force  
    }
    catch [Exception] {
        $_.message 
        exit
    }
}

#Check of Microsoft.Graph.Groups is installed.
if (Get-Module -ListAvailable -Name Microsoft.Graph.Groups) {
    Write-Host "Microsoft.Graph.Groups Already Installed"
} else {
    try {
        Install-Module -Name Microsoft.Graph.Groups -Repository PSGallery -Confirm:$False -Force  
    }
    catch [Exception] {
        $_.message 
        exit
    }
}

#################################################################################################

function New-MEMAPPUploader {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("NotepadPlusPlus",`
        "7Zip",`
        "GreenShot",`
        "AdobeAcrobatDC_Dutch",`
        "AdobeAcrobatDC_English",`
        "CitrixWorkspaceApp",`
        "FileZilla",`
        "FoxitReader_Dutch",`
        "FoxitReader_English",`
        "Chrome", `
        "KeePass_Dutch", `
        "MicrosoftNETDesktop", `
        "MicrosoftEdge_Dutch", IgnoreCase = $false)]
        [string[]]$Productname
)
##########################################
#   Import-Module
##########################################
    Import-Module Microsoft.Graph.Groups
    Import-Module Evergreen
    Import-Module IntuneWin32App
##########################################
#   Setting folder structure
##########################################
    $Path = 'Download'
    $Drive = 'C:\Win32App'
    $LocalPath = $Drive + '\' + $Path
    Remove-Item -Path $LocalPath -Recurse -ErrorAction SilentlyContinue
    New-Item -Path $Drive -Name $Path  -ItemType Directory -ErrorAction SilentlyContinue
    Set-Location $LocalPath
##########################################
#   Download Applications.xml
##########################################
    $XML = "$LocalPath\Applications.xml"
    $XMLURL = "https://raw.githubusercontent.com/knowledgebaseit/Temp/main/Applications.xml"
    $ProgressPreference = 'SilentlyContinue'
    #Write-Host "Download the XML file"
    Invoke-WebRequest -UseBasicParsing -Uri $XMLURL -OutFile $XML
##########################################
#   Download Icons.zip
##########################################
    Set-Location $Drive
    $ZIP = "Icons.zip"
    $ZIPURL = "https://raw.githubusercontent.com/knowledgebaseit/Microsoft365/main/Endpoint/MEMAPPWIMUploader/Icons.zip"
    #Invoke-WebRequest -Uri $ZIPURL -OutFile $ZIP
    #Expand-Archive -LiteralPath "$Drive\Icons.zip" -DestinationPath $Drive -Force   
##########################################
#   Download Software
##########################################
    Set-Location $LocalPath
    $MyConfigFileloc = ("$XML")
    [xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)
    foreach ($Productname in $Productname)
    { 
        foreach ($App in $MyConfigFile.Applications.ChildNodes){
            If ($App.Product -match $Productname) {
                $Product = $App.Product
                $Download = Invoke-Expression $App.Download -ErrorAction SilentlyContinue
                $PackageName = "$Product"
                $Version = $Download.Version
                $InstallerType = $App.Installer
                $Architecture = $App.Architecture
                $DisplayNames = $($App.Product) + " " + $Version + " " + "($Architecture)"
                $Source = "$PackageName" + "_" + "$Version" + "_" + "$Architecture" + "." + "$InstallerType"
                $InstallScript = $app.install
                $UninstallScript = $app.uninstall
                $MailNickName = "M" + (Get-Random -Minimum 999 -Maximum 99999)
                $URL = $Download.uri
                $Logo = $App.Logo 
                Write-Host "Download $Product"
                Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Source
##########################################
#   Removing old AppAssignment
##########################################
                $GetIntuneWin32App = Get-IntuneWin32App | Where-Object {$_.DisplayName -like "$Product*"}
                ForEach ($GetIntuneWin32App in $GetIntuneWin32App) {
                    Remove-IntuneWin32AppAssignment -ID $GetIntuneWin32App.id
                    Write-Host "Removing old AppAssignment $Product"
                }
##########################################
#   Removing old Apps
##########################################
                $GetIntuneWin32App = Get-IntuneWin32App | Where-Object {$_.DisplayName -like "$Product*"}
                if ($GetIntuneWin32App.count -gt 3) {
                    do{
                        $GetIntuneWin32App = Get-IntuneWin32App | Where-Object {$_.DisplayName -like "$Product*"}
                        $time0 = $GetIntuneWin32App.createdDateTime
                        $date0 = $time0.Substring(0,10)
                        $getdate = Get-Date -Format yyyy-MM-dd
                        $Oldappdays0 = New-TimeSpan -Start $date0[0] -End $getdate
                            if ($Oldappdays0.Days -gt -1) {
                                Remove-IntuneWin32App -Id $GetIntuneWin32App.id[0]
                            }
                    }until ($GetIntuneWin32App.count -le 4)
                }
##########################################
#   Creating Intunewin
##########################################
                New-Item -ItemType directory -Path $LocalPath\Temp
                Copy-Item -Path $Source -Destination $LocalPath\Temp
                Out-File -FilePath  "$LocalPath\Temp\InstallScript.ps1" -Encoding unicode -Force -InputObject $InstallScript -Confirm:$false
                Out-File -FilePath  "$LocalPath\Temp\UninstallScript.ps1" -Encoding unicode -Force -InputObject $UninstallScript -Confirm:$false
                ((Get-Content -path "$LocalPath\Temp\InstallScript.ps1" -Raw) -replace '<Source>',$Source) | Set-Content -Path "$LocalPath\Temp\InstallScript.ps1"
                ((Get-Content -path "$LocalPath\Temp\UninstallScript.ps1" -Raw) -replace '<Source>',$Source) | Set-Content -Path "$LocalPath\Temp\UninstallScript.ps1"
                ((Get-Content -path "$LocalPath\Temp\UninstallScript.ps1" -Raw) -replace '<Name>',$App.Name) | Set-Content -Path "$LocalPath\Temp\UninstallScript.ps1"
                Write-Host "Creating Intune Application for $($App.DisplayName) $Version ($Architecture)"
                Write-Host "Vendor = $App.Vendor"
                $Win32AppPackage = New-IntuneWin32AppPackage -SourceFolder $LocalPath\Temp -SetupFile $Source -OutputFolder $LocalPath
##########################################
#   Convert image file to icon
##########################################
                $Icons = "$Drive\Icons"
                if (!(Test-Path -Path $Icons\$Logo.png)) {
                    $ImageFile = "$Icons\MSI.png"
                    $Icon = New-IntuneWin32AppIcon -FilePath $ImageFile
                }else
                {
                    $ImageFile = "$Icons\$Logo.png"
                    $Icon = New-IntuneWin32AppIcon -FilePath $ImageFile
                }
##########################################
#   Upload Intunewin
##########################################
                # Get Application meta data from .intunewin file
                $IntuneWinFile = $Win32AppPackage.Path
                $IntuneWinMetaData = Get-IntuneWin32AppMetaData -FilePath $IntuneWinFile
                # Create custom display name
                If ($App.Installer -eq "msi") {
                    $ProductCode = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductCode
                    $InstallCommandLine = "powershell.exe -executionpolicy bypass .\InstallScript.ps1"
                    $UninstallCommandLine = "powershell.exe -executionpolicy bypass .\UninstallScript.ps1"
                    $DetectionRule = New-IntuneWin32AppDetectionRuleMSI -ProductCode $ProductCode -ProductVersionOperator "greaterThanOrEqual" -ProductVersion $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion
                    $Win32App = Add-IntuneWin32App -FilePath $IntuneWinFile -DisplayName $DisplayNames -Description $App.Description -Publisher $App.Vendor -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -InstallCommandLine $InstallCommandLine -UninstallCommandLine $UninstallCommandLine -Icon $Icon -CompanyPortalFeaturedApp $true
                    # Installgroup
                    if ($null -eq (Get-MgGroup | Where-Object {($_.DisplayName -like "MEM_WIN_APP_INSTALL_$Product")})) {
                        $installgroup = New-MgGroup -DisplayName "MEM_WIN_APP_INSTALL_$Product" -MailEnabled:$False -MailNickName $MailNickName -SecurityEnabled
                        $installgroup = Get-MgGroup | Where-Object { ($_.DisplayName -like "MEM_WIN_APP_INSTALL_$Product") }
                    }else {
                        $installgroup = Get-MgGroup | Where-Object { ($_.DisplayName -like "MEM_WIN_APP_INSTALL_$Product") }
                        Write-Host "Group MEM_WIN_APP_INSTALL_$Product already exists"
                    }
                    $installid = $installgroup.Id
                    Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $installid -Intent "required" -Notification "hideAll" -Verbose
                    # Uninstallgroup
                    if ($null -eq (Get-MgGroup | Where-Object {($_.DisplayName -like "MEM_WIN_APP_UNINSTALL_$Product")})) {
                        $uninstallgroup = New-MgGroup -DisplayName "MEM_WIN_APP_UNINSTALL_$Product" -MailEnabled:$False -MailNickName $MailNickName -SecurityEnabled
                        $uninstallgroup = Get-MgGroup | Where-Object { ($_.DisplayName -like "MEM_WIN_APP_UNINSTALL_$Product") }
                    }else {
                        $uninstallgroup = Get-MgGroup | Where-Object { ($_.DisplayName -like "MEM_WIN_APP_UNINSTALL_$Product") }
                        Write-Host "Group MEM_WIN_APP_UNINSTALL_$Product already exists"
                    }
                    $uninstallid = $uninstallgroup.Id
                    Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $uninstallid -Intent "uninstall" -Notification "hideAll" -Verbose
                }
                If ($App.Installer -eq "exe") {
                    #$DetectionRule = New-IntuneWin32AppDetectionRuleScript -ScriptFile $DetectionScriptFile -EnforceSignatureCheck $false -RunAs32Bit $false
                    $DetectionRule = New-IntuneWin32AppDetectionRuleFile -Existence -DetectionType exists -Path $App.Path -FileOrFolder $App.DetectionFolder -Check32BitOn64System $false
                    $InstallCommandLine = "powershell.exe -executionpolicy bypass .\InstallScript.ps1"
                    $UninstallCommandLine = "powershell.exe -executionpolicy bypass .\UninstallScript.ps1"
                    $Win32App = Add-IntuneWin32App -FilePath $IntuneWinFile -DisplayName $DisplayNames -Description "$($App.Description)" -Developer "" -Owner "" -Publisher $App.Vendor -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -InstallCommandLine $InstallCommandLine -UninstallCommandLine $UninstallCommandLine -Icon $Icon -CompanyPortalFeaturedApp $true
                    # Installgroup
                    if ($null -eq (Get-MgGroup | Where-Object {($_.DisplayName -like "MEM_WIN_APP_INSTALL_$Product")})) {
                        $installgroup = New-MgGroup -DisplayName "MEM_WIN_APP_INSTALL_$Product" -MailEnabled:$False -MailNickName $MailNickName -SecurityEnabled
                        $installgroup = Get-MgGroup | Where-Object { ($_.DisplayName -like "MEM_WIN_APP_INSTALL_$Product") }
                    }else {
                        $installgroup = Get-MgGroup | Where-Object { ($_.DisplayName -like "MEM_WIN_APP_INSTALL_$Product") }
                        Write-Host "Group MEM_WIN_APP_INSTALL_$Product already exists"
                    }
                    $installid = $installgroup.Id
                    Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $installid -Intent "required" -Notification "hideAll" -Verbose
                    # Uninstallgroup
                    if ($null -eq (Get-MgGroup | Where-Object {($_.DisplayName -like "MEM_WIN_APP_UNINSTALL_$Product")})) {
                        $uninstallgroup = New-MgGroup -DisplayName "MEM_WIN_APP_UNINSTALL_$Product" -MailEnabled:$False -MailNickName $MailNickName -SecurityEnabled
                        $uninstallgroup = Get-MgGroup | Where-Object { ($_.DisplayName -like "MEM_WIN_APP_UNINSTALL_$Product") }
                    }else {
                        $uninstallgroup = Get-MgGroup | Where-Object { ($_.DisplayName -like "MEM_WIN_APP_UNINSTALL_$Product") }
                        Write-Host "Group MEM_WIN_APP_UNINSTALL_$Product already exists"
                    }
                    $uninstallid = $uninstallgroup.Id
                    Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $uninstallid -Intent "uninstall" -Notification "hideAll" -Verbose        
                }
##########################################
#   Remove temp
##########################################
                    Remove-Item -Path $LocalPath\Temp -Confirm:$false -Recurse
                    Start-Sleep -s 30
            }
        }
    }
}
