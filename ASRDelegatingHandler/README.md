## ASRDelegatingHandler
Project to modify URLs (Endpoint and\or ProviderNameSpace) while calling rest APIs.

### Usage examples:

* To point ASR\RecoveryServices vault  calls in powershell session to BVT add following to the script:
```powershell
Add-Type -Path ASRDelegatingHandler.dll
$handler = New-Object -TypeName ASRDelegatingHandler.ASRDelegatingHandler("Microsoft.RecoveryServicesBVTD2");
[Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.ClientFactory.AddHandler($handler);
```
* To point ASR calls in powershell session to one box while working with production vault add following to the script:
```powershell
Add-Type -Path ASRDelegatingHandler.dll
$handler = New-Object -TypeName ASRDelegatingHandler.ASRDelegatingHandler("", "https://avrai-z240:8443/Rdfeproxy.svc");
[Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.ClientFactory.AddHandler($handler);
```
* To point ASR calls in powershell session to one box while working with BVT vault, add following to the script:
```powershell
Add-Type -Path ASRDelegatingHandler.dll
$handler = New-Object -TypeName ASRDelegatingHandler.ASRDelegatingHandler("Microsoft.RecoveryServicesBVTD2", "https://avrai-z240:8443/Rdfeproxy.svc");
[Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.ClientFactory.AddHandler($handler);
```
