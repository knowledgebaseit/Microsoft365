<#Author       : Dennis Westerman
# Creation Date: 2021-08-07
# Usage        : AutoPilotMenu to add Grouptag to a AutoPilot Device
#*********************************************************************************
# Date                  Version     Changes
#------------------------------------------------------------------------
# 2021-08-07            1.0         Intial Version
#
#*********************************************************************************
#
#>

##########################################
#    Install.ps1    #
##########################################
$appName = 'AutoPilotMenu'
$drive = 'C:\Temp'
New-Item -Path $drive -Name $appName  -ItemType Directory -ErrorAction SilentlyContinue
$LocalPath = $drive + '\' + $appName 
set-Location $LocalPath

$APMPS1 = 'https://raw.githubusercontent.com/knowledgebaseit/Microsoft365/main/Endpoint/Powershell/AutoPilotMenu-Script.ps1'
$APMPS1DL = 'Upload_Device_Group_Tag.ps1'
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $APMPS1 -OutFile $APMPS1DL

Set-Location -Path C:\\Temp\\AutoPilotMenu
.\Upload_Device_Group_Tag.ps1
