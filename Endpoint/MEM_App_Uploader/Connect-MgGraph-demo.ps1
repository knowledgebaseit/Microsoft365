$ApplicationID = '05661007-c06c-45ba-92a5-59a5e0d9a1ff'
$ApplicationKey = 'yFDZUigsKx268rKxEVYq3/K6QWgrDP9oUrhNnBofm98='
$TenantDomain = 'vfl66.onmicrosoft.com'
$TenantId = 'd6580653-28dc-4d5b-812b-bed824396545'
$Resource = 'https://graph.microsoft.com'

Import-module Microsoft.Graph.Users
Import-module Microsoft.Graph.Intune
Import-module Microsoft.Graph.Groups
Import-module IntuneWin32App

$Body = @{
    grant_type    = "client_credentials"
    resource      = $Resource
    client_id     = $ApplicationID
    client_secret = $ApplicationKey
}

$Authorization = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$($TenantDomain)/oauth2/token" -Body $body -ErrorAction Stop

#$Authorization.token_type
#$Authorization.access_token
Connect-MgGraph -AccessToken $Authorization.access_token

#New-MsalClientApplication -ClientId 'a2be79e1-f221-4c65-a23a-361ca64311a0'
#Select-MsalClientApplication -ClientId 'a2be79e1-f221-4c65-a23a-361ca64311a0'

Connect-MSIntuneGraph -TenantID $tenantId -ClientID $ApplicationID -ClientSecret $ApplicationKey
Clear-Host