# Param(

#   # [Parameter(Mandatory = $false,

#   #            HelpMessage="Identifier of the Azure subscription to be used.")]

#   # [ValidateNotNullOrEmpty()]

#   # [string]$subscriptionId,



#   # [Parameter(Mandatory = $false, 

#   #            HelpMessage="Name of the resource group to which the Virtual Machines belong.")]

#   # [ValidateNotNullOrEmpty()]

#   # [string]$resourceGroupName,



#   # [Parameter(Mandatory = $false,

#   #            HelpMessage="Comma-separated name(s) of the virtual machines.")]

#   # [ValidateNotNullOrEmpty()]

#   # [string[]]$vmNameArray=@(),



#   # [Parameter(Mandatory = $false,

#   #            HelpMessage="Name of the KeyVault in which encryption secret is kept.")]

#   # [ValidateNotNullOrEmpty()]

#   # [string]$secondaryBEKVault,


  
#   [Parameter(Mandatory = $false,

#              HelpMessage="Name of the AAD application that will be used to write secrets to KeyVault.")]

#   [ValidateNotNullOrEmpty()]

#   [string]$aadAppName,



#   [Parameter(Mandatory = $false,

#              HelpMessage="Client secret of the AAD application that was created earlier")]

#   [string]$aadClientSecret



#   # [Parameter(Mandatory = $false,

#   #            HelpMessage="Name of the KeyVault in which encryption key for the secret is kept")]

#   # [string]$secondaryKEKVault


# )

$ErrorActionPreference = "Stop"

Login-AzureRmAccount -ErrorAction Stop;

$UserInputForm                   = New-Object system.Windows.Forms.Form;
$subLabel                        = New-Object system.Windows.Forms.Label;
$subDropDown                     = New-Object system.Windows.Forms.ComboBox;
$rgLabel                         = New-Object system.Windows.Forms.Label;
$rgDropDown                      = New-Object system.Windows.Forms.ComboBox;
$vmLabel                         = New-Object system.Windows.Forms.Label;
$vmListBox                       = New-Object System.Windows.Forms.CheckedListBox;
$locationLabel                   = New-Object system.Windows.Forms.Label;
$locationDropDown                = New-Object system.Windows.Forms.ComboBox;
$bekLabel                        = New-Object system.Windows.Forms.Label;
$bekTextBox                      = New-Object system.Windows.Forms.TextBox;
$kekLabel                        = New-Object system.Windows.Forms.Label;
$kekTextBox                      = New-Object system.Windows.Forms.TextBox;
$selectButton                    = New-Object system.Windows.Forms.Button;

$formElements = @($subLabel,$subDropDown,$rgLabel,$rgDropDown,$vmLabel,$vmListBox,$locationLabel,$locationDropDown,$bekLabel,$bekTextBox,$kekLabel,$kekTextBox,$selectButton);

$locations = (Get-AzureRmLocation).Location | sort;


function Get-ResourceGroups

{

    $subName = $subDropDown.SelectedItem.ToString();

    if($subName)

    {

        Select-AzureRmSubscription -SubscriptionName $subName;

        $rgLabel.enabled = $true;
        $rgDropDown.enabled = $true;

        $rgDropDown.Items.Clear();
        $vmListBox.Items.Clear();

        [array]$rgArray = (Get-AzureRmResourceGroup).ResourceGroupName | sort;

        ForEach ($item in $rgArray) 

        {

            $suppress_output = $rgDropDown.Items.Add($item);

        }

        for($i = 4; $i -lt $formElements.Count; $i++)

        {

            ($formElements[$i]).enabled = $false;

        }

    }

}

function Get-VirtualMachines

{

    $rgName = $rgDropDown.SelectedItem.ToString();

    if($rgName)

    {

        $vmLabel.enabled = $true;
        $vmListBox.enabled = $true;
        $locationLabel.enabled = $true;
        $locationDropDown.enabled = $true;

        $vmListBox.Items.Clear();

        $locationDropDown.Items.Clear();

        $vmList = (Get-AzureRmVm -ResourceGroupName $rgName).Name | sort;

        ForEach ($item in $vmList) 

        {

            $suppress_output = $vmListBox.Items.Add($item);

        }

        ForEach ($item in $locations) 

        {

            $suppress_output = $locationDropDown.Items.Add($item);

        }

        for($i = 8; $i -lt $formElements.Count; $i++)

        {

            ($formElements[$i]).enabled = $false;

        }

    }

}

function Enable-RestOfOptions

{

    $locName = $locationDropDown.SelectedItem.ToString();

    if($locName)

    {

        for($i = 8; $i -lt $formElements.Count; $i++)

        {

            ($formElements[$i]).enabled = $true;

        }

        $bekTextBox.text = "";

        $kekTextBox.text = "";

    }

}

function Get-AllSelections

{

    $script:resourceGroupName = $rgDropDown.SelectedItem.ToString();

    [array]$script:vmNameArray = $vmListBox.CheckedItems;

    $script:targetLocation = $locationDropDown.SelectedItem.ToString();

    $script:secondaryBEKVault = $bekTextBox.text;

    $script:secondaryKEKVault = $kekTextBox.text;

    # $resourceGroupName = $rgDropDown.SelectedItem.ToString();

    # [array]$vmNameArray = $vmListBox.CheckedItems;

    # $script:targetLocation = $locationDropDown.SelectedItem.ToString();

    # $secondaryBEKVault = $bekTextBox.text;

    # $secondaryKEKVault = $kekTextBox.text;

    $UserInputForm.Close();

}

Add-Type -AssemblyName System.Windows.Forms;
[System.Windows.Forms.Application]::EnableVisualStyles();

$UserInputForm.ClientSize        = '800,520';
$UserInputForm.text              = "User Inputs";
$UserInputForm.BackColor         = "#ffffff";
$UserInputForm.TopMost           = $false;

$subLabel.text                   = "Subscription";
$subLabel.AutoSize               = $true;
$subLabel.width                  = 88;
$subLabel.height                 = 30;
$subLabel.location               = New-Object System.Drawing.Point(162,26);
$subLabel.Font                   = 'Microsoft Sans Serif,9';
$subLabel.ForeColor              = "#5c7290";

$subDropDown.width               = 424;
$subDropDown.height              = 66;
$subDropDown.location            = New-Object System.Drawing.Point(162,57);
$subDropDown.Font                = 'Microsoft Sans Serif,9';
$subDropDown.ForeColor           = "#5c7290";
$subDropDown.Add_SelectedIndexChanged({Get-ResourceGroups});

$rgDropDown.width                = 424;
$rgDropDown.height               = 60;
$rgDropDown.enabled              = $false;
$rgDropDown.location             = New-Object System.Drawing.Point(162,125);
$rgDropDown.Font                 = 'Microsoft Sans Serif,9';
$rgDropDown.ForeColor            = "#5c7290";
$rgDropDown.Add_SelectedIndexChanged({Get-VirtualMachines});

$rgLabel.text                    = "Resource Group";
$rgLabel.AutoSize                = $true;
$rgLabel.enabled                 = $false;
$rgLabel.width                   = 25;
$rgLabel.height                  = 10;
$rgLabel.location                = New-Object System.Drawing.Point(162,99);
$rgLabel.Font                    = 'Microsoft Sans Serif,9';
$rgLabel.ForeColor               = "#5c7290";

$vmListBox.width                 = 424;
$vmListBox.height                = 50;
$vmListBox.enabled               = $false;
$vmListBox.CheckOnClick          = $true;
$vmListBox.location              = New-Object System.Drawing.Point(162,195);
$vmListBox.Font                    = 'Microsoft Sans Serif,9';
$vmListBox.ForeColor               = "#5c7290";

$vmLabel.text                    = "Choose virtual machine(s)";
$vmLabel.AutoSize                = $true;
$vmLabel.enabled                 = $false;
$vmLabel.width                   = 25;
$vmLabel.height                  = 10;
$vmLabel.location                = New-Object System.Drawing.Point(162,169);
$vmLabel.Font                    = 'Microsoft Sans Serif,9';
$vmLabel.ForeColor               = "#5c7290";

$bekTextBox.multiline            = $false;
$bekTextBox.width                = 424;
$bekTextBox.height               = 30;
$bekTextBox.enabled              = $false;
$bekTextBox.location             = New-Object System.Drawing.Point(162,351);
$bekTextBox.Font                 = 'Microsoft Sans Serif,9';
$bekTextBox.ForeColor            = "#5c7290";

$bekLabel.text                   = "Target BEK vault";
$bekLabel.AutoSize               = $true;
$bekLabel.enabled                = $false;
$bekLabel.width                  = 25;
$bekLabel.height                 = 10;
$bekLabel.location               = New-Object System.Drawing.Point(162,326);
$bekLabel.Font                   = 'Microsoft Sans Serif,9';
$bekLabel.ForeColor              = "#5c7290";

$kekTextBox.multiline            = $false;
$kekTextBox.width                = 424;
$kekTextBox.height               = 30;
$kekTextBox.enabled              = $false;
$kekTextBox.location             = New-Object System.Drawing.Point(162,412);
$kekTextBox.Font                 = 'Microsoft Sans Serif,9';
$kekTextBox.ForeColor            = "#5c7290";

$kekLabel.text                   = "Target KEK vault";
$kekLabel.AutoSize               = $true;
$kekLabel.enabled                = $false;
$kekLabel.width                  = 25;
$kekLabel.height                 = 10;
$kekLabel.location               = New-Object System.Drawing.Point(162,386);
$kekLabel.Font                   = 'Microsoft Sans Serif,10';
$kekLabel.ForeColor              = "#5c7290";

$locationDropDown.width          = 424;
$locationDropDown.height         = 20;
$locationDropDown.enabled        = $false;
$locationDropDown.location       = New-Object System.Drawing.Point(162,292);
$locationDropDown.Font           = 'Microsoft Sans Serif,9';
$locationDropDown.ForeColor      = "#5c7290";
$locationDropDown.Add_SelectedIndexChanged({Enable-RestOfOptions});

$locationLabel.text              = "Target Location";
$locationLabel.AutoSize          = $true;
$locationLabel.enabled           = $false;
$locationLabel.width             = 25;
$locationLabel.height            = 10;
$locationLabel.location          = New-Object System.Drawing.Point(162,266);
$locationLabel.Font              = 'Microsoft Sans Serif,9';
$locationLabel.ForeColor         = "#5c7290";

$selectButton.BackColor          = "#eeeeee";
$selectButton.text               = "Select";
$selectButton.width              = 75;
$selectButton.height             = 30;
$selectButton.enabled            = $false;
$selectButton.location           = New-Object System.Drawing.Point(332,450);
$selectButton.Font               = 'Microsoft Sans Serif,9';
$selectButton.ForeColor          = "#5c7290";
$selectButton.Add_Click({Get-AllSelections});

$msLogo                          = New-Object system.Windows.Forms.PictureBox
$msLogo.width                    = 147
$msLogo.height                   = 85
$msLogo.location                 = New-Object System.Drawing.Point(10,10)
$msLogo.imageLocation            = "https://c.s-microsoft.com/en-us/CMSImages/ImgOne.jpg?version=D418E733-821C-244F-37F9-DC865BDEFEC0"
$msLogo.SizeMode                 = [System.Windows.Forms.PictureBoxSizeMode]::zoom

[array]$subArray = ((Get-AzureRmSubscription).Name | sort);

ForEach ($item in $subArray) 

{

    $suppressOutput = $subDropDown.Items.Add($item);

}

$UserInputForm.controls.AddRange($formElements);
$UserInputForm.controls.AddRange($msLogo);

[void]$UserInputForm.ShowDialog();

#############################################################################
# End of User Input - GUI and params
#############################################################################

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

$tenantId = (Get-AzureRmContext).Tenant.Id;

foreach($vmName in $script:vmNameArray)

{

    $vm = Get-AzureRmVM -Name $vmName -ResourceGroupName $script:resourceGroupName;

    if($vm.StorageProfile.OsDisk.EncryptionSettings.Enabled -eq "True")

    {

        $BEK = $vm.StorageProfile.OsDisk.EncryptionSettings.DiskEncryptionKey;

        $KEK = $vm.StorageProfile.OsDisk.EncryptionSettings.KeyEncryptionKey;

        if(-not $BEK)

        {

            Write-Error 'Virtual Machine not Encrypted';

        }

        $BEKvaultres = Get-AzureRmResource -ResourceId $BEK.SourceVault.Id;

        [uri]$URL = $BEK.SecretUrl;

        $BEKSecret = Get-AzureKeyVaultSecret -VaultName $BEKvaultres.Name -Name $URL.Segments[2].TrimEnd("/") -Version $URL.Segments[3];
      
        $BEKSecretBase64 = $BEKSecret.SecretValueText;

        $tags = $BEKSecret.Attributes.Tags;

        # Checking if secondary BEK Vault exists

        if(-not $script:secondaryBEKVault)

        {

            $script:secondaryBEKVault = "$($BEKvaultres.Name)" + "-asr";

        }

        $secondaryVaultObject = Get-AzureRmKeyVault -VaultName $script:secondaryBEKVault;

        if(-not $secondaryVaultObject)

        {

            Write-Host "Target BEK key vault: $script:secondaryBEKVault does not exist. Creating a new key vault at target location: $script:targetLocation";

            $targetRgName = "$script:resourceGroupName" + "-asr";

            $rgObject = Get-AzureRmResourceGroup -Name $targetRgName -ErrorAction SilentlyContinue;

            if(-not $rgObject)

            {

                Write-Host "Target resource group: $targetRgName does not exist. Creating resource group."

                New-AzureRmResourceGroup -Name $targetRgName -Location $script:targetLocation;

            }

            $kv = Get-AzureRmKeyVault -VaultName $BEKvaultres.Name;
             
            New-AzureRmKeyVault -VaultName $script:secondaryBEKVault -ResourceGroupName $targetRgName -Location $script:targetLocation -EnabledForDeployment:$kv.EnabledForDeployment -EnabledForTemplateDeployment:$kv.EnabledForTemplateDeployment -EnabledForDiskEncryption:$kv.EnabledForDiskEncryption -EnableSoftDelete:$kv.EnableSoftDelete -Sku $kv.Sku -Tag $kv.Tags;         

        }

        if($KEK)

        {

            $BEKEncryptionAlgorithm = $BEKSecret.Attributes.Tags.DiskEncryptionKeyEncryptionAlgorithm;

            $KEKvaultres = Get-AzureRmResource -ResourceId $KEK.SourceVault.Id;

            [uri]$URL = $KEK.KeyUrl;

            if(-not $script:secondaryKEKVault)

            {
                # Getting secondary KEK vault name and ensuring its existence

                $script:secondaryKEKVault = "$($KEKvaultres.Name)" + "-asr";

                Write-Host "Secondary KEK Vault: $script:secondaryKEKVault will be used";

            }

            $secondaryVaultObject = Get-AzureRmKeyVault -VaultName $script:secondaryKEKVault;

            if(-not $secondaryVaultObject)

            {
                Write-Host "Target KEK key vault: $script:secondaryKEKVault does not exist. Creating a new key vault at target location: $script:targetLocation";

                $targetRgName = "$script:resourceGroupName" + "-asr";

                $rgObject = Get-AzureRmResourceGroup -Name $targetRgName -ErrorAction SilentlyContinue;

                if(-not $rgObject)

                {

                    Write-Host "Target resource group: $targetRgName does not exist. Creating resource group."

                    New-AzureRmResourceGroup -Name $targetRgName -Location $script:targetLocation;

                }

                $kv = Get-AzureRmKeyVault -VaultName $KEKvaultres.Name;
                
                New-AzureRmKeyVault -VaultName $script:secondaryKEKVault -ResourceGroupName $targetRgName -Location $script:targetLocation -EnabledForDeployment:$kv.EnabledForDeployment -EnabledForTemplateDeployment:$kv.EnabledForTemplateDeployment -EnabledForDiskEncryption:$kv.EnabledForDiskEncryption -EnableSoftDelete:$kv.EnableSoftDelete -Sku $kv.Sku -Tag $kv.Tags;         

            }

            $KEKKey = Get-AzureKeyVaultKey -VaultName $KEKvaultres.Name -Name $URL.Segments[2].TrimEnd("/") -Version $URL.Segments[3];
      
            # Creating a new key in the secondary KEK vault

            $new_KEK = Add-AzureKeyVaultKey -VaultName $script:secondaryKEKVault -Name $KEKKey.Name -Destination Software;

            $targetKEKURI = "https://" + "$script:secondaryKEKVault" + ".vault.azure.net/keys/" + $new_KEK.Name + '/' + $new_KEK.Version;

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

                $aadClientSecret = Read-Host  -Prompt "Input corresponding azure AD App ClientSecret.";

            }

            $aadClientID = $SvcPrincipals[0].ApplicationId;

            $servicePrincipal = $SvcPrincipals[0];

            Set-AzureRmKeyVaultAccessPolicy -VaultName $KEKvaultres.Name -ObjectId $servicePrincipal.Id -PermissionsToKeys decrypt -PermissionsToSecrets all;

            Set-AzureRmKeyVaultAccessPolicy -VaultName $script:secondaryKEKVault -ObjectId $servicePrincipal.Id -PermissionsToKeys encrypt -PermissionsToSecrets all;

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

            Set-AzureKeyVaultSecret -VaultName $script:secondaryBEKVault -Name $BEKSecret.Name -SecretValue $secureSecret -tags $tags -ContentType "Wrapped BEK";

        }

        else

        {

            $secureSecret = ConvertTo-SecureString $BEKSecretBase64 -AsPlainText -Force;

            Set-AzureKeyVaultSecret -VaultName $script:secondaryBEKVault -Name $BEKSecret.Name -SecretValue $secureSecret -tags $tags -ContentType "BEK";

        }

    }

}