$FeatureNames = @( "Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Redirect","Web-Http-Logging","Web-Custom-Logging","Web-Custom-Logging",
                  "Web-Log-Libraries","Web-Request-Monitor","Web-Http-Tracing","Web-Stat-Compression","Web-Dyn-Compression","Web-Filtering","Web-Basic-Auth","Web-CertProvider",
                  "Web-Client-Auth","Web-Digest-Auth","Web-Cert-Auth","Web-IP-Security","Web-Url-Auth","Web-Windows-Auth","Web-Net-Ext","Web-Net-Ext45","Web-Asp-Net","Web-Asp-Net45",
                  "Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Ftp-Service","Web-Ftp-Ext","Web-Mgmt-Console","Web-Scripting-Tools","NET-Framework-Core","NET-HTTP-Activation","NET-Non-HTTP-Activ",
                  "NET-Framework-45-Core","NET-Framework-45-ASPNET","NET-WCF-HTTP-Activation45","NET-WCF-MSMQ-Activation45","NET-WCF-Pipe-Activation45","NET-WCF-TCP-Activation45","NET-WCF-TCP-PortSharing45",
                  "Web-WHC","MSMQ-Server","PowerShell","PowerShell-V2","PowerShell-ISE","WAS-Process-Model","WAS-NET-Environment","WAS-Config-APIs","WoW64-Support")

$featureObjects =  Get-WindowsFeature

""
""
"Features already Installed:"
foreach($featureName in $FeatureNames)
{
    $featureObjects | Where-Object {$_.Name -contains $featureName -and $_.InstallState -eq "Installed"}
}


""
""
"Installing features:"
foreach($featureName in $FeatureNames)
{
    $featureObjects | Where-Object {$_.Name -contains $featureName -and $_.InstallState -eq "Available"} | Install-WindowsFeature
}

""
""
"Final status of features"
$featureObjects =  Get-WindowsFeature
$featureObjects

""
""
"Final status of the features:"
foreach($featureName in $FeatureNames)
{

    $featureObjects | Where-Object {$_.Name -contains $featureName}
}
