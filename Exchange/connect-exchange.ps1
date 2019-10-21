$UserCredential = Get-Credential
$ExhcangeServer = "server.com"
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExhcangeServer/PowerShell/ -Authentication Kerberos -Credential $UserCredential
Import-PSSession $Session -DisableNameChecking
