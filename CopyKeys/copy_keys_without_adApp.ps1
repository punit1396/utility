Param(

  [Parameter(Mandatory = $true,

             HelpMessage="Identifier of the Azure subscription to be used.")]

  [ValidateNotNullOrEmpty()]

  [string]$subscriptionId,



  [Parameter(Mandatory = $true, 

             HelpMessage="Name of the resource group to which the Virtual Machines belong.")]

  [ValidateNotNullOrEmpty()]

  [string]$resourceGroupName,



  [Parameter(Mandatory = $true,

             HelpMessage="Comma-separated name(s) of the virtual machines.")]

  [ValidateNotNullOrEmpty()]

  [string[]]$vmNameArray=@(),



  [Parameter(Mandatory = $true,

             HelpMessage="Name of the KeyVault in which encryption secret is kept.")]

  [ValidateNotNullOrEmpty()]

  [string]$secondaryBEKVault,


  
  [Parameter(Mandatory = $false,

             HelpMessage="Name of the AAD application that will be used to write secrets to KeyVault.")]

  [ValidateNotNullOrEmpty()]

  [string]$aadAppName,



  [Parameter(Mandatory = $false,

             HelpMessage="Client secret of the AAD application that was created earlier")]

  [string]$aadClientSecret,



  [Parameter(Mandatory = $false,

             HelpMessage="Name of the KeyVault in which encryption key for the secret is kept")]

  [string]$secondaryKEKVault


)

$ErrorActionPreference = "Stop"



$azureResourcesModule = Get-Module 'AzureRM.Resources';


# Function to generate token for vault access

function Generate-Token
(

    [string]$tenantId,

    $appId,

    $appKey

)
{    

    $tokenEndpoint = {https://login.windows.net/{0}/oauth2/token} -f $tenantId;

    $ARMresource = "https://vault.azure.net";

    $body = 
      @{

           'resource' = $ARMresource

           'client_id' = $appId

           'grant_type' = 'client_credentials'

           'client_secret' = $appKey

      }

    $params = 
        @{

            contenttype='application/x-www-form-urlencoded'

            Headers = @{'accept'='application/json'}

            Body = $body

            Method = 'POST'

            URI = $tokenEndpoint
        }

    Write-Host "Client Id: $appId";
    Write-Host "Client Secret: $appKey";

    $token = Invoke-RestMethod @params;

    if(-not $token)

    {

        Write-Error 'Token could not be generated';

    }

    else 

    {
      
        Write-Host 'Token generated successfully';

    }

    return $token.access_token;

}


# Function to encrypt BEK using new KEK

function Encrypt-Secret
(

    $value,

    [string]$encryptionAlgorithm,

    [string]$access_token,

    [string]$keyId

)
{

    $body = 
        @{

            'value' = $value

            'alg' = $encryptionAlgorithm

        }

    $body_json = ConvertTo-Json -InputObject $body;

    $params =
        @{

            ContentType = 'application/json'

            Headers = 
                @{

                    'authorization'="Bearer $access_token"
                }

            Method = 'POST'

            URI = "$keyId" + '/encrypt?api-version=2016-10-01'

            Body = $body_json
        }

    $response = Invoke-RestMethod @params;

    if(-not $response)

    {

        Write-Error "BEK couldn't be encrypted";

    }

    else 

    {
      
        Write-Host "BEK encrypted successfully";

    }

    return $response;

}


# Function to decrypt the wrapped BEK using original KEK

function Decrypt-Secret
(

    $encryptedValue,

    [string]$encryptionAlgorithm,

    [string]$access_token,

    [string]$keyId

)
{

    $body = 
        @{

            'value' = $encryptedValue

            'alg' = $encryptionAlgorithm

        }

    $body_json = ConvertTo-Json -InputObject $body;

    $params = 
        @{

            ContentType = 'application/json'

            Headers = 
                @{

                    'authorization'="Bearer $access_token"
                }

            Method = 'POST'

            URI = "$keyId" + '/decrypt?api-version=2016-10-01'

            Body = $body_json
        
        }

    $response = Invoke-RestMethod @params;

    if(-not $response)

    {

        Write-Error "Wrapped BEK couldn't be decrypted";

    }

    else 

    {
      
        Write-Host "Wrapped BEK decrypted successfully";

    }

    return $response;

}

# Selecting the Azure AD to work with

Select-AzureRmSubscription -SubscriptionId $subscriptionId;

$tenantId = (Get-AzureRmContext).Tenant.Id;

foreach($vmName in $vmNameArray)

{

    $vm = Get-AzureRmVM -Name $vmName -ResourceGroupName $resourceGroupName;

    if($vm.StorageProfile.OsDisk.EncryptionSettings.Enabled -eq "True")

    {

        $BEK = $vm.StorageProfile.OsDisk.EncryptionSettings.DiskEncryptionKey;

        $KEK = $vm.StorageProfile.OsDisk.EncryptionSettings.KeyEncryptionKey;

        if(-not $BEK)

        {

            Write-Error 'Virtual Machine not Encrypted';

        }

        #copy BEK Secret to Secondary KeyVault

        $BEKvaultres = Get-AzureRmResource -ResourceId $BEK.SourceVault.Id;

        [uri]$URL = $BEK.SecretUrl;

        $BEKSecret = Get-AzureKeyVaultSecret -VaultName $BEKvaultres.Name -Name $URL.Segments[2].TrimEnd("/") -Version $URL.Segments[3];
      
        $BEKSecretBase64 = $BEKSecret.SecretValueText;

        $tags = $BEKSecret.Attributes.Tags;

        # Checking if secondary BEK Vault exists

        $secondaryVaultObject = Get-AzureRmKeyVault -VaultName $secondaryBEKVault;

        if(-not $secondaryVaultObject)

        {

            Write-Error "Secondary BEK key vault: $secondaryBEKVault does not exist";

        }

        if($KEK)

        {

            if(-not $secondaryKEKVault)

            {
                # Getting secondary KEK vault name and ensuring its existence

                $secondaryKEKVault = Read-Host -ErrorAction SilentlyContinue -Prompt 'Input secondary KEK vault name and hit ENTER. If nothing entered then secondary BEK vault name will be used';

                if(-not $secondaryKEKVault)

                {

                    $secondaryKEKVault = $secondaryBEKVault;

                }

                else 

                {

                    $secondaryVaultObject = Get-AzureRmKeyVault -VaultName $secondaryKEKVault;

                    if(-not $secondaryVaultObject)

                    {

                        Write-Error "Secondary KEK key vault: $secondaryKEKVault does not exist";

                    }
                    
                }

                Write-Host "Secondary KEK Vault: $secondaryKEKVault";

            }

            $BEKEncryptionAlgorithm = $BEKSecret.Attributes.Tags.DiskEncryptionKeyEncryptionAlgorithm;

            $KEKvaultres = Get-AzureRmResource -ResourceId $KEK.SourceVault.Id;

            [uri]$URL = $KEK.KeyUrl;

            $KEKKey = Get-AzureKeyVaultKey -VaultName $KEKvaultres.Name -Name $URL.Segments[2].TrimEnd("/") -Version $URL.Segments[3];
      
            # Creating a new key in the secondary KEK vault

            $new_KEK = Add-AzureKeyVaultKey -VaultName $secondaryKEKVault -Name $KEKKey.Name -Destination Software;

            $targetKEKURI = "https://" + "$secondaryKEKVault" + ".vault.azure.net/keys/" + $new_KEK.Name + '/' + $new_KEK.Version;

            # Setting Key vault access for the azure AD App

            if(-not $aadAppName)

            {

                $aadAppName = Read-Host  -Prompt "Enter the Azure AD application name you want to use." ;

            }

            $SvcPrincipals = (Get-AzureRmADServicePrincipal -SearchString $aadAppName);

            if(-not $SvcPrincipals)

            {

                # AAD app wasn't created 

                Write-Error "Failed to find an aad application named $aadAppName";

                return;

            }

            if(-not $aadClientSecret)

            {

                $aadClientSecret = Read-Host  -Prompt "Input corresponding azyre AD App ClientSecret.";

            }

            $aadClientID = $SvcPrincipals[0].ApplicationId;

            $servicePrincipal = $SvcPrincipals[0];

            Set-AzureRmKeyVaultAccessPolicy -VaultName $KEKvaultres.Name -ObjectId $servicePrincipal.Id -PermissionsToKeys decrypt -PermissionsToSecrets all;

            Set-AzureRmKeyVaultAccessPolicy -VaultName $secondaryKEKVault -ObjectId $servicePrincipal.Id -PermissionsToKeys encrypt -PermissionsToSecrets all;

            # Generating Token

            $access_token = Generate-Token -tenantId $tenantId -appId $aadClientID -appKey $aadClientSecret;

            # Decrypting Wrapped-BEK

            $unEncrypted = Decrypt-Secret -encryptedValue $BEKSecretBase64 -encryptionAlgorithm $BEKEncryptionAlgorithm -access_token $access_token -keyId $KEKkey.Key.Kid;

            Write-Host "Unecrypted: $($unEncrypted.value)" -ForegroundColor Green;

            # Encrypting BEK with new KEK

            $encrypted = Encrypt-Secret -value $unEncrypted.value -encryptionAlgorithm $BEKEncryptionAlgorithm -access_token $access_token -keyId $targetKEKURI;

            Write-Host "Encrypted: $($encrypted.value)" -ForegroundColor Green;

            $tags.DiskEncryptionKeyEncryptionKeyURL = $targetKEKURI;

            $secureSecret = ConvertTo-SecureString $encrypted.value -AsPlainText -Force;

            #

            Set-AzureKeyVaultSecret -VaultName $secondaryBEKVault -Name $BEKSecret.Name -SecretValue $secureSecret -tags $tags -ContentType "Wrapped BEK";

        }

        else

        {

            $secureSecret = ConvertTo-SecureString $BEKSecretBase64 -AsPlainText -Force;

            Set-AzureKeyVaultSecret -VaultName $secondaryBEKVault -Name $BEKSecret.Name -SecretValue $secureSecret -tags $tags -ContentType "BEK";

        }

    }

}