Param(

  [Parameter(Mandatory = $true,

             HelpMessage="Identifier of the Azure subscription to be used")]

  [ValidateNotNullOrEmpty()]

  [string]$subscriptionId,


  
  [Parameter(Mandatory = $true,

             HelpMessage="Name of the AAD application that will be used to write secrets to KeyVault. A new application with this name will be created if one doesn't exist. If this app already exists, pass aadClientSecret parameter to the script")]

  [ValidateNotNullOrEmpty()]

  [string]$aadAppName
)

$ErrorActionPreference = "Stop"

# Selecting the Azure AD to work with

Select-AzureRmSubscription -SubscriptionId $subscriptionId;

# Check if AAD app with $aadAppName was already created

$SvcPrincipals = (Get-AzureRmADServicePrincipal -SearchString $aadAppName);

if(-not $SvcPrincipals)

{

    # Create a new AD application if not created before

    Write-Host "AAD application ($aadAppName) does not exist"

    $identifierUri = [string]::Format("http://localhost:8080/{0}",[Guid]::NewGuid().ToString("N"));

    $defaultHomePage = 'http://contoso.com';

    $now = [System.DateTime]::Now;

    $oneYearFromNow = $now.AddYears(1);

    $script:aadClientSecret = [Guid]::NewGuid().ToString();

    Write-Host "Creating new AAD application ($aadAppName)";



    if($azureResourcesModule.Version.Major -ge 5)

    {

        $secureAadClientSecret = ConvertTo-SecureString -String $script:aadClientSecret -AsPlainText -Force;

        $ADApp = New-AzureRmADApplication -DisplayName $aadAppName -HomePage $defaultHomePage -IdentifierUris $identifierUri  -StartDate $now -EndDate $oneYearFromNow -Password $secureAadClientSecret;

    }

    else

    {

        $ADApp = New-AzureRmADApplication -DisplayName $aadAppName -HomePage $defaultHomePage -IdentifierUris $identifierUri  -StartDate $now -EndDate $oneYearFromNow -Password $script:aadClientSecret;

    }



    $servicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $ADApp.ApplicationId;

    $SvcPrincipals = (Get-AzureRmADServicePrincipal -SearchString $aadAppName);

    if(-not $SvcPrincipals)

    {

        # AAD app wasn't created 

        Write-Error "Failed to create AAD app $aadAppName. Please log in to Azure using Connect-AzureRmAccount and try again";

        return;

    }

    $script:aadClientID = $servicePrincipal.ApplicationId;

}

else

{
    # Creating a new secret for existing Azure AD application

    Write-Host "AAD application ($aadAppName) already present. Generating new secret."

    $script:aadClientID = $SvcPrincipals[0].ApplicationId;

    $servicePrincipal = $SvcPrincipals[0];

    $script:aadClientSecret = [Guid]::NewGuid().ToString();

    $res = New-AzureRmADAppCredential -ApplicationId $script:aadClientID -Password $script:aadClientSecret;


    if(-not $res)
    {
        Write-Error 'Secret could not be generated. Ensure you are logged in and try again.' ;
    }

}

Write-Host "Azure AD App Name: $aadAppName" -ForegroundColor Green;
Write-Host "Azure AD App ID: $($script:aadClientID)" -ForegroundColor Green;
Write-Host "Azure AD App Secret: $($script:aadClientSecret)" -ForegroundColor Green;