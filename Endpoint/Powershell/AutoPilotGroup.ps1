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
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue) {
    Write-Host "NuGet Already Installed"
} 
else {
    try {
        Install-PackageProvider -Name NuGet -Confirm:$False -Force  
    }
    catch [Exception] {
        $_.message 
        exit
    }
}

if (Get-Module -ListAvailable -Name AzureAD) {
    Write-Host "AzureAD Already Installed"
} 
else {
    try {
        Install-Module -Name AzureAD -AllowClobber -Confirm:$False -Force  
    }
    catch [Exception] {
        $_.message 
        exit
    }
}

if (Get-Module -ListAvailable -Name PSIntuneAuth) {
    Write-Host "PSIntuneAuth Already Installed"
} 
else {
    try {
        Install-Module -Name PSIntuneAuth -AllowClobber -Confirm:$False -Force  
    }
    catch [Exception] {
        $_.message 
        exit
    }
}

if (Get-InstalledScript -Name Upload-WindowsAutopilotDeviceInfo -ErrorAction SilentlyContinue) {
    Write-Host "Upload-WindowsAutopilotDeviceInfo Already Installed"
} 
else {
    try {
        Install-Script -Name Upload-WindowsAutopilotDeviceInfo -force  
    }
    catch [Exception] {
        $_.message 
        exit
    }
}

Import-Module AzureAD
Connect-AzureAD

$Domain = Get-AzureADDomain | where {($_.name -like '*.onmicrosoft.com')}
$Onmicrosoft = $Domain.Name

$Tenantname = "vitamnl.onmicrosoft.com"
$GroupTags = "Shared","Personal"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Add Autopilot device menu'
$form.Size = New-Object System.Drawing.Size(400,250)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(165,180)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(250,180)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(360,40)
$label.Text = 'Choose the type of device that you want to add:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,60)
$listBox.Size = New-Object System.Drawing.Size(360,20)
$listBox.Height = 80

foreach ($GroupTag in $GroupTags){
    [void] $listBox.Items.Add($GroupTag)
}

$form.Controls.Add($listBox)

$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $x = $listBox.SelectedItem
 
    Write-Host "Adding the device as $($x)"
        
    # collect Windows Autopilot info and Upload it to Azure
    Upload-WindowsAutopilotDeviceInfo.ps1 -TenantName $Tenantname -GroupTag $x -Verbose
	
}