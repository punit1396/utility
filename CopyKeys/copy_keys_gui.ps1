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

$suppress_output = Login-AzureRmAccount -ErrorAction Stop;

Add-Type -AssemblyName System.Windows.Forms;
[System.Windows.Forms.Application]::EnableVisualStyles();

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
$bekDropDown                     = New-Object system.Windows.Forms.ComboBox;
$kekLabel                        = New-Object system.Windows.Forms.Label;
$kekDropDown                     = New-Object system.Windows.Forms.ComboBox;
$loadingLabel                        = New-Object system.Windows.Forms.Label;
$selectButton                    = New-Object system.Windows.Forms.Button;
$infoToolTip                     = New-Object System.Windows.Forms.ToolTip;

$formElements = @($subLabel,$subDropDown,$rgLabel,$rgDropDown,$vmLabel,$vmListBox,$locationLabel,$locationDropDown,$bekLabel,$bekDropDown,$kekLabel,$kekDropDown,$selectButton);

$rp = Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute;

# Locations taken from resource type: availabilitySets instead of resource type: Virtual machines just to stay in parallel with the Portal.

$locations = ($rp[0].Locations) | %{ $_.Split(' ').tolower() -join ''} | sort; #(Get-AzureRmLocation).Location | sort;

function Show-Help

{
  
    $infoToolTip.SetToolTip($this,$this.Tag);

}

function Get-ResourceGroups

{

    $subName = $subDropDown.SelectedItem.ToString();

    if($subName)

    {

        $loadingLabel.Text = "Loading resource groups";

        Select-AzureRmSubscription -SubscriptionName $subName;

        $rgLabel.enabled = $true;
        $rgDropDown.enabled = $true;

        $rgDropDown.Items.Clear();
        $vmListBox.Items.Clear();

        $rgDropDown.Text = "";

        [array]$rgArray = (Get-AzureRmResourceGroup).ResourceGroupName | sort;

        ForEach ($item in $rgArray) 

        {

            $suppress_output = $rgDropDown.Items.Add($item);

        }

        $suppress_output = $rgDropDown.Items.Add($rgArray);

        for($i = 4; $i -lt $formElements.Count; $i++)

        {

            ($formElements[$i]).enabled = $false;

        }

        $loadingLabel.Text = "";

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

        $locationDropDown.Text = "";

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

function Disable-RestOfOptions

{

    $locationDropDown.Text = "";

    $bekDropDown.Text = "";

    $kekDropDown.Text = "";
    
    for($i = 8; $i -lt $formElements.Count; $i++)

    {
        if($formElements[$i].Text -ne 'Not Applicable')

        {

            ($formElements[$i]).enabled = $false;

        }

    }

}

function Get-KeyVaults

{
    
    $locName = $locationDropDown.SelectedItem.ToString();

    if($locName)

    {

        $loadingLabel.Text = "Loading target BEK vault";

        $vmSelected = $vmListBox.CheckedItems;

        $failCount = 0;

        if($vmSelected)

        {
            $bek = $kek = "";

            $i = 0;

            while((-not $kek) -and ($i -lt $vmSelected.Count))

            {

                $vm = Get-AzureRmVM -ResourceGroupName $rgDropDown.SelectedItem.ToString() -Name $vmSelected[$i];

                if($vm.StorageProfile.OsDisk.EncryptionSettings.Enabled -eq "True")

                {                

                    if(-not $bek)

                    {

                        $bek = $vm.StorageProfile.OsDisk.EncryptionSettings.DiskEncryptionKey;

                    }

                    $kek = $vm.StorageProfile.OsDisk.EncryptionSettings.KeyEncryptionKey;

                }

                $i++;

            }

            if(-not $bek)

            {

                $bekDropDown.Text = "Not Applicable"

                $bekDropDown.Enabled = $false;

                $failCount += 1;

            }

            else
             
            {

                $bekKvName = $bek.SourceVault.Id.Split('/')[-1] + '-asr';

                $bekKvObj = Get-AzureRmResource -Name $bekKvName;

                if(-not $bekKvObj)

                {

                    $bekKvName = '(new)' + $bekKvName;
                    
                    $bekDropDown.Items.Add($bekKvName);

                }

                $bekDropDown.Text = $bekKvName;

            }
            
            $loadingLabel.Text = "Loading target KEK vault";
            
            if(-not $kek)

            {

                $kekDropDown.Text = "Not Applicable"

                $kekDropDown.Enabled = $false;
                
                $failCount += 1;

            }            

            else
             
            {

                $kekKvName = $kek.SourceVault.Id.Split('/')[-1] + '-asr';

                $kekKvObj = Get-AzureRmResource -Name $kekKvName;

                if(-not $kekKvObj)

                {
                    $kekKvName = '(new)' + $kekKvName;
                    
                    $kekDropDown.Items.Add($kekKvName);

                }

                $kekDropDown.Text = $kekKvName;

            }

            if(($failCount -lt 2) -and ($bekDropDown.Items.Count -le 1))

            {

                $kvList = (Get-AzureRmKeyVault).VaultName | sort;

                ForEach ($item in $kvList) 
        
                {
        
                    $suppress_output = $bekDropDown.Items.Add($item);
        
                    $suppress_output = $kekDropDown.Items.Add($item);
        
                }  
        
            }

            if($failCount -lt 2)

            {
                    
                for($i = 8; $i -lt $formElements.Count; $i++)

                {
                    if($formElements[$i].Text -ne 'Not Applicable')

                    {

                        ($formElements[$i]).enabled = $true;

                    }

                }

            }

            $loadingLabel.Text = "";
            
        }

        else 
        
        {
            
            $bekDropDown.Items.Clear();

            $kekDropDown.Items.Clear();
            
        }

    }

}

function Get-AllSelections

{

    $script:resourceGroupName = $rgDropDown.SelectedItem.ToString();

    [array]$script:vmNameArray = $vmListBox.CheckedItems;

    $script:targetLocation = $locationDropDown.SelectedItem.ToString();

    $bekKv = $bekDropDown.Text.Split(')');

    $script:secondaryBEKVault = $bekKv[$bekKv.Count - 1];

    $kekKv = $kekDropDown.Text.Split(')');

    $script:secondarykEKVault = $kekKv[$kekKv.Count - 1];

    # $resourceGroupName = $rgDropDown.SelectedItem.ToString();

    # [array]$vmNameArray = $vmListBox.CheckedItems;

    # $script:targetLocation = $locationDropDown.SelectedItem.ToString();

    # $secondaryBEKVault = $bekDropDown.text;

    # $secondaryKEKVault = $kekDropDown.text;

    $UserInputForm.Close();

}

$UserInputForm.ClientSize        = '445,600';
$UserInputForm.text              = "User Inputs";
$UserInputForm.BackColor         = "#ffffff";
$UserInputForm.TopMost           = $false;

$subLabel.text                   = "Subscription";
$subLabel.AutoSize               = $true;
$subLabel.width                  = 88;
$subLabel.height                 = 30;
$subLabel.location               = New-Object System.Drawing.Point(10,90);
$subLabel.Font                   = 'Microsoft Sans Serif,9';
$subLabel.ForeColor              = "#5c7290";
$subLabel.Tag                    = "Hover message: subscription";
$subLabel.Add_MouseHover({Show-Help});

$subDropDown.width               = 424;
$subDropDown.height              = 66;
$subDropDown.location            = New-Object System.Drawing.Point(10,121);
$subDropDown.Font                = 'Microsoft Sans Serif,9';
$subDropDown.ForeColor           = "#5c7290";
$subDropDown.DropDownHeight      = 150;
$subDropDown.Add_SelectedIndexChanged({Get-ResourceGroups});

$rgDropDown.width                = 424;
$rgDropDown.height               = 60;
$rgDropDown.enabled              = $false;
$rgDropDown.location             = New-Object System.Drawing.Point(10,189);
$rgDropDown.Font                 = 'Microsoft Sans Serif,9';
$rgDropDown.ForeColor            = "#5c7290";
$rgDropDown.DropDownHeight       = 150;
$rgDropDown.Add_SelectedIndexChanged({Get-VirtualMachines});

$rgLabel.text                    = "Resource Group";
$rgLabel.AutoSize                = $true;
$rgLabel.enabled                 = $false;
$rgLabel.width                   = 25;
$rgLabel.height                  = 10;
$rgLabel.location                = New-Object System.Drawing.Point(10,163);
$rgLabel.Font                    = 'Microsoft Sans Serif,9';
$rgLabel.ForeColor               = "#5c7290";
$rgLabel.Tag                     = "Hover message: resource group";
$rgLabel.Add_MouseHover({Show-Help});

$vmListBox.width                 = 424;
$vmListBox.height                = 95;
$vmListBox.enabled               = $false;
$vmListBox.CheckOnClick          = $true;
$vmListBox.location              = New-Object System.Drawing.Point(10,255);
$vmListBox.Font                  = 'Microsoft Sans Serif,9';
$vmListBox.ForeColor             = "#5c7290";
$vmListBox.Add_SelectedIndexChanged({Disable-RestOfOptions});

$vmLabel.text                    = "Choose virtual machine(s)";
$vmLabel.AutoSize                = $true;
$vmLabel.enabled                 = $false;
$vmLabel.width                   = 25;
$vmLabel.height                  = 10;
$vmLabel.location                = New-Object System.Drawing.Point(10,233);
$vmLabel.Font                    = 'Microsoft Sans Serif,9';
$vmLabel.ForeColor               = "#5c7290";
$vmLabel.Tag                     = "Hover message: virtual machine";
$vmLabel.Add_MouseHover({Show-Help});

$bekDropDown.width               = 424;
$bekDropDown.height              = 30;
$bekDropDown.enabled             = $false;
$bekDropDown.location            = New-Object System.Drawing.Point(10,445);
$bekDropDown.Font                = 'Microsoft Sans Serif,9';
$bekDropDown.ForeColor           = "#5c7290";
$bekDropDown.DropDownHeight      = 150;

$bekLabel.text                   = "Target BEK vault";
$bekLabel.AutoSize               = $true;
$bekLabel.enabled                = $false;
$bekLabel.width                  = 25;
$bekLabel.height                 = 10;
$bekLabel.location               = New-Object System.Drawing.Point(10,420);
$bekLabel.Font                   = 'Microsoft Sans Serif,9';
$bekLabel.ForeColor              = "#5c7290";
$bekLabel.Tag                    = "Hover message: bek";
$bekLabel.Add_MouseHover({Show-Help});

$kekDropDown.width               = 424;
$kekDropDown.height              = 30;
$kekDropDown.enabled             = $false;
$kekDropDown.location            = New-Object System.Drawing.Point(10,506);
$kekDropDown.Font                = 'Microsoft Sans Serif,9';
$kekDropDown.ForeColor           = "#5c7290";
$kekDropDown.DropDownHeight      = 150;

$kekLabel.text                   = "Target KEK vault";
$kekLabel.AutoSize               = $true;
$kekLabel.enabled                = $false;
$kekLabel.width                  = 25;
$kekLabel.height                 = 10;
$kekLabel.location               = New-Object System.Drawing.Point(10,480);
$kekLabel.Font                   = 'Microsoft Sans Serif,10';
$kekLabel.ForeColor              = "#5c7290";
$kekLabel.Tag                    = "Hover message: kek";
$kekLabel.Add_MouseHover({Show-Help});

$locationDropDown.width          = 424;
$locationDropDown.height         = 20;
$locationDropDown.enabled        = $false;
$locationDropDown.location       = New-Object System.Drawing.Point(10,386);
$locationDropDown.Font           = 'Microsoft Sans Serif,9';
$locationDropDown.ForeColor      = "#5c7290";
$locationDropDown.DropDownHeight = 150;
$locationDropDown.Add_SelectedIndexChanged({Get-KeyVaults});

$locationLabel.text              = "Target Location";
$locationLabel.AutoSize          = $true;
$locationLabel.enabled           = $false;
$locationLabel.width             = 25;
$locationLabel.height            = 10;
$locationLabel.location          = New-Object System.Drawing.Point(10,360);
$locationLabel.Font              = 'Microsoft Sans Serif,9';
$locationLabel.ForeColor         = "#5c7290";
$locationLabel.Tag               = "Hover message: location";
$locationLabel.Add_MouseHover({Show-Help});

$loadingLabel.text              = "";
$loadingLabel.AutoSize          = $true;
$loadingLabel.width             = 25;
$loadingLabel.height            = 10;
$loadingLabel.location          = New-Object System.Drawing.Point(150,535);
$loadingLabel.Font              = 'Microsoft Sans Serif,9';
$loadingLabel.ForeColor         = "#5c7290";
$loadingLabel.Add_MouseHover({Show-Help});

$selectButton.BackColor          = "#eeeeee";
$selectButton.text               = "Select";
$selectButton.width              = 75;
$selectButton.height             = 30;
$selectButton.enabled            = $false;
$selectButton.location           = New-Object System.Drawing.Point(184,556);
$selectButton.Font               = 'Microsoft Sans Serif,10';
$selectButton.ForeColor          = "#5c7290";
$selectButton.Add_Click({Get-AllSelections});

$msLogo                          = New-Object system.Windows.Forms.PictureBox
$msLogo.width                    = 140
$msLogo.height                   = 80
$msLogo.location                 = New-Object System.Drawing.Point(150,10)
$msLogo.imageLocation            = "https://c.s-microsoft.com/en-us/CMSImages/ImgOne.jpg?version=D418E733-821C-244F-37F9-DC865BDEFEC0"
$msLogo.SizeMode                 = [System.Windows.Forms.PictureBoxSizeMode]::zoom

[array]$subArray = ((Get-AzureRmSubscription).Name | sort);

ForEach ($item in $subArray) 

{

    $suppressOutput = $subDropDown.Items.Add($item);

}

$UserInputForm.controls.AddRange($formElements + $loadingLabel);
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

function Generate-TokenFromPowershell
(
         
    [string]$tenantId

)
{    

    $ARMresource = "https://vault.azure.net";

    $clientId = "1950a258-227b-4e31-a9cf-717495945fc2";

    $redirectUri = "urn:ietf:wg:oauth:2.0:oob";

    $authorityUri = "https://login.windows.net/$tenantId";
    
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authorityUri;
    
    $authResult = $authContext.AcquireToken($ARMresource, $clientId, $redirectUri, "Auto");
 
    return $authResult.AccessToken;

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

    $response = Invoke-RestMethod @params -ErrorAction SilentlyContinue;

    if(-not $response)

    {

        Write-Error "BEK could not be encrypted. Make sure you have the required permissions.";

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

        Write-Error "BEK could not be encrypted. Make sure you have the required permissions.";

    }

    return $response;

}

$tenantId = (Get-AzureRmContext).Tenant.Id;

$bekSrcPermissions = @('Get');

$bekTarPermissions = @('Set');

$kekSrcPermissions = @('Get', 'Decrypt');

$kekTarPermissions = @('Create', 'Encrypt');


$userPrincipalName = (Get-AzureRmContext).Account.Id;

$objId = (Get-AzureRmADUser -UserPrincipalName $userPrincipalName).Id;

foreach($vmName in $script:vmNameArray)

{

    $vm = Get-AzureRmVM -Name $vmName -ResourceGroupName $script:resourceGroupName;

    if($vm.StorageProfile.OsDisk.EncryptionSettings.Enabled -eq "True")

    {

        $BEK = $vm.StorageProfile.OsDisk.EncryptionSettings.DiskEncryptionKey;

        $KEK = $vm.StorageProfile.OsDisk.EncryptionSettings.KeyEncryptionKey;

        if(-not $BEK)

        {

            Write-Error "Virtual machine $vmName encrypted but disk encryption key details missing";

        }

        $isNewBekKv = $false;

        $BEKvaultres = Get-AzureRmResource -ResourceId $BEK.SourceVault.Id;

        
        if($aadAppName)

        {
            $SvcPrincipals = (Get-AzureRmADServicePrincipal -SearchString $aadAppName);

            if(-not $SvcPrincipals)

            {

                # AAD app wasn't created 

                Write-Error "Failed to find an aad application named $aadAppName";

                return;

            }

            $aadClientID = $SvcPrincipals[0].ApplicationId;

            $servicePrincipal = $SvcPrincipals[0];

            $objId = $servicePrincipal.Id;

        }
        
        # Checking whether user has required permissions to the Source BEK Key vault

        foreach($policy in $BEKvaultres.Properties.AccessPolicies)

        {

            if ($policy.ObjectId -eq $objId)

            {                   

                if(($bekSrcPermissions | %{ $policy.permissions.secrets.Contains($_)}) -contains $false)

                {

                    Write-Error "Access denied. Ensure you have $($bekSrcPermissions -join ', ') permission(s) for the secrets of key vault $($BEKvaultres.Name)";

                }

                break;

            }
            
        }

        [uri]$URL = $BEK.SecretUrl;

        $BEKSecret = Get-AzureKeyVaultSecret -VaultName $BEKvaultres.Name -Name $URL.Segments[2].TrimEnd("/") -Version $URL.Segments[3];
      
        $BEKSecretBase64 = $BEKSecret.SecretValueText;

        $tags = $BEKSecret.Attributes.Tags;

        $secondaryVaultObject = Get-AzureRmKeyVault -VaultName $script:secondaryBEKVault;

        if(-not $secondaryVaultObject)

        {

            $isNewBekKv = $true;

            Write-Host "Creating key vault $script:secondaryBEKVault" -ForegroundColor Green;

            $script:targetBekRgName = "$($BEKvaultres.ResourceGroupName)" + "-asr";

            $rgObject = Get-AzureRmResourceGroup -Name $script:targetBekRgName -ErrorAction SilentlyContinue;

            if(-not $rgObject)

            {

                New-AzureRmResourceGroup -Name $script:targetBekRgName -Location $script:targetLocation;

            }

            # $script:kv = Get-AzureRmKeyVault -VaultName $BEKvaultres.Name;
             
            $suppress_output = New-AzureRmKeyVault -VaultName $script:secondaryBEKVault -ResourceGroupName $script:targetBekRgName -Location $script:targetLocation -EnabledForDeployment:$BEKvaultres.Properties.EnabledForDeployment -EnabledForTemplateDeployment:$BEKvaultres.Properties.EnabledForTemplateDeployment -EnabledForDiskEncryption:$BEKvaultres.Properties.EnabledForDiskEncryption -EnableSoftDelete:$BEKvaultres.Properties.EnableSoftDelete -Sku $BEKvaultres.Properties.Sku.name -Tag $BEKvaultres.Tags;         

        }

        else 
        
        {

            # Checking whether user has required permissions to the Target BEK Key vault

            foreach($policy in $secondaryVaultObject.AccessPolicies)

            {

                if ($policy.ObjectId -eq $objId)

                {                   

                    if(($bekTarPermissions | %{ $policy.PermissionsToSecrets.Contains($_)}) -contains $false)

                    {

                        Write-Error "Access denied. Ensure you have $($bekTarPermissions -join ', ') permission(s) for the secrets of key vault $($secondaryVaultObject.VaultName)";

                    }

                    break;

                }
                
            }

        }

        if($KEK)

        {

            $isNewKekKv = $false;

            $BEKEncryptionAlgorithm = $BEKSecret.Attributes.Tags.DiskEncryptionKeyEncryptionAlgorithm;

            $KEKvaultres = Get-AzureRmResource -ResourceId $KEK.SourceVault.Id;

            [uri]$URL = $KEK.KeyUrl;

            # Checking whether user has required permissions to the Source KEK Key vault
            
            foreach($policy in $KEKvaultres.Properties.AccessPolicies)

            {

                if ($policy.ObjectId -eq $objId)

                {                   

                    if(($kekSrcPermissions | %{ $policy.permissions.Keys.Contains($_)}) -contains $false)

                    {

                        Write-Error "Access denied. Ensure you have $($kekSrcPermissions -join ', ') permission(s) for the keys of key vault $($KEKvaultres.Name)";

                    }

                    break;

                }
                
            }

            # Checking if secondary KEK vault exists

            $script:secondaryVaultObject = Get-AzureRmKeyVault -VaultName $script:secondaryKEKVault;

            if(-not $script:secondaryVaultObject)

            {

                $isNewKekKv = $true;

                # Creating a new key vault as the secondary key vault

                Write-Host "Creating key vault $script:secondaryKEKVault" -ForegroundColor Green;

                $script:targetKekRgName = "$($KEKvaultres.ResourceGroupName)" + "-asr";

                # Checking if target resource group exists

                $rgObject = Get-AzureRmResourceGroup -Name $script:targetKekRgName -ErrorAction SilentlyContinue;

                if(-not $rgObject)

                {

                    # Creating target resource group

                    New-AzureRmResourceGroup -Name $script:targetKekRgName -Location $script:targetLocation;

                }

                # $script:kv = Get-AzureRmKeyVault -VaultName $KEKvaultres.Name;
                
                $suppress_output = New-AzureRmKeyVault -VaultName $script:secondaryKEKVault -ResourceGroupName $script:targetKekRgName -Location $script:targetLocation -EnabledForDeployment:$KEKvaultres.Properties.EnabledForDeployment -EnabledForTemplateDeployment:$KEKvaultres.Properties.EnabledForTemplateDeployment -EnabledForDiskEncryption:$KEKvaultres.Properties.EnabledForDiskEncryption -EnableSoftDelete:$KEKvaultres.Properties.EnableSoftDelete -Sku $KEKvaultres.Properties.Sku.name -Tag $KEKvaultres.Tags;         

            }          

            else 
            
            {
                
                # Checking whether user has required permissions to the Target KEK Key vault

                foreach($policy in $script:secondaryVaultObject.AccessPolicies)

                {

                    if ($policy.ObjectId -eq $objId)

                    {                   

                        if(($kekTarPermissions | %{ $policy.PermissionsToKeys.Contains($_)}) -contains $false)

                        {

                            Write-Error "Access denied. Ensure you have $($kekTarPermissions -join ', ') permission(s) for the keys of key vault $($script:secondaryVaultObject.VaultName)";

                        }

                        break;

                    }
                    
                }

            }

            $KEKKey = Get-AzureKeyVaultKey -VaultName $KEKvaultres.Name -Name $URL.Segments[2].TrimEnd("/") -Version $URL.Segments[3];
      
            # Creating a new key in the secondary KEK vault

            $new_KEK = Add-AzureKeyVaultKey -VaultName $script:secondaryKEKVault -Name $KEKKey.Name -Destination Software;

            $targetKEKURI = "https://" + "$script:secondaryKEKVault" + ".vault.azure.net/keys/" + $new_KEK.Name + '/' + $new_KEK.Version;

            # Setting Key vault access for the azure AD App

            ##########################################################
            # if using AAD app
            ##########################################################
            if($aadAppName)

            {

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

                # Generating Token

                $script:access_token = Generate-Token -tenantId $tenantId -appId $aadClientID -appKey $aadClientSecret;
                
                #Adding encryption permission for the target key vault iff the target key vault is newly created

                if($isNewKekKv -or ($isNewBekKv -and ($script:secondaryBEKVault -eq $script:secondaryKEKVault)))
                
                {

                    Set-AzureRmKeyVaultAccessPolicy -VaultName $script:secondaryKEKVault -ObjectId $servicePrincipal.Id -PermissionsToKeys 'Decrypt';

                }

            }

            else 
            
            {

                $script:access_token = Generate-TokenFromPowershell -tenantId $tenantId;

                $userPrincipalName = (Get-AzureRmContext).Account.Id;

                # $userObjectId = (Get-AzureRmADUser -UserPrincipalName $userPrincipalName).Id;

                if($isNewKekKv -or ($isNewBekKv -and ($script:secondaryBEKVault -eq $script:secondaryKEKVault)))
                
                {

                    Set-AzureRmKeyVaultAccessPolicy -VaultName $script:secondaryKEKVault -UserPrincipalName $userPrincipalName -PermissionsToKeys 'Encrypt';

                }

            }

            Write-Host 'Copying "Key Encryption Key" for' "$vmName" -ForegroundColor Green;
            
            # Decrypting Wrapped-BEK

            $unEncrypted = Decrypt-Secret -encryptedValue $BEKSecretBase64 -encryptionAlgorithm $BEKEncryptionAlgorithm -access_token $script:access_token -keyId $KEKkey.Key.Kid;

            # Encrypting BEK with new KEK

            $encrypted = Encrypt-Secret -value $unEncrypted.value -encryptionAlgorithm $BEKEncryptionAlgorithm -access_token $script:access_token -keyId $targetKEKURI;

            $tags.DiskEncryptionKeyEncryptionKeyURL = $targetKEKURI;

            $secureSecret = ConvertTo-SecureString $encrypted.value -AsPlainText -Force;

            # Copying newly wrapped BEK secret to the secondary vault
            
            Write-Host 'Copying "Disk Encryption Key" for' "$vmName" -ForegroundColor Green;

            $suppress_output = Set-AzureKeyVaultSecret -VaultName $script:secondaryBEKVault -Name $BEKSecret.Name -SecretValue $secureSecret -tags $tags -ContentType "Wrapped BEK";

            # Copying all access policies to newly created kek Key Vault in case of kek and bek having different target key vaults

            if($isNewKekKv)

            {

                $i = 0;

                foreach($accessPolicy in $KEKvaultres.Properties.AccessPolicies)

                {

                    $setPolicyCommand = "Set-AzureRmKeyVaultAccessPolicy -VaultName $script:secondaryKEKVault -ResourceGroupName $script:targetKekRgName -ObjectId $($accessPolicy.ObjectId)" + ' ';
                        
                    if($accessPolicy.permissions.keys)

                    {

                        $addKeys = "-PermissionsToKeys $($accessPolicy.Permissions.Keys -join ',')" + ' ';

                        $setPolicyCommand += $addKeys;

                    }

                    if($accessPolicy.permissions.secrets)
    
                    {
    
                        $addSecrets = "-PermissionsToSecrets $($accessPolicy.Permissions.Secrets -join ',')" + ' ';
    
                        $setPolicyCommand += $addSecrets;
    
                    }
                    
                    if($accessPolicy.permissions.certificates)
    
                    {
    
                        $addCertificates = "-PermissionsToCertificates $($accessPolicy.Permissions.Certificates -join ',')" + ' ';
    
                        $setPolicyCommand += $addCertificates;
    
                    }
                    
                    if($accessPolicy.permissions.storage)
    
                    {
    
                        $addStorage = "-PermissionsToStorage $($accessPolicy.Permissions.Storage -join ',')" + ' ';
    
                        $setPolicyCommand += $addStorage;
    
                    }
    
                    $setPolicyCommand += ';';
    
                    Invoke-Expression -Command $setPolicyCommand;
                    
                    $i++;
    
                    Write-Progress -Activity "Copying access policies from $($KEKvaultres.Name) to $script:secondaryKEKVault" -status "Access Policy $i of $( $KEKvaultres.Properties.AccessPolicies.Count)" -percentComplete ($i / $KEKvaultres.Properties.AccessPolicies.Count*100)

                }

            }

        }

        else

        {

            # Copying BEK secret to the secondary vault

            Write-Host 'Copying "Disk Encryption Key" for ' + "$vmName" -ForegroundColor Green;

            $secureSecret = ConvertTo-SecureString $BEKSecretBase64 -AsPlainText -Force;

            $suppress_output = Set-AzureKeyVaultSecret -VaultName $script:secondaryBEKVault -Name $BEKSecret.Name -SecretValue $secureSecret -tags $tags -ContentType "BEK";

        }

        # Copying all access policies to newly created bek Key Vault in case only bek or bek and kek having same target key vaults 

        if($isNewBekKv)

        {
            $i = 0;

            foreach($accessPolicy in $BEKvaultres.Properties.AccessPolicies)

            {
                
                $setPolicyCommand = "Set-AzureRmKeyVaultAccessPolicy -VaultName $script:secondaryBEKVault -ResourceGroupName $script:targetBekRgName -ObjectId $($accessPolicy.ObjectId)" + ' ';

                if($accessPolicy.permissions.keys)

                {

                    $addKeys = "-PermissionsToKeys $($accessPolicy.Permissions.Keys -join ',')" + ' ';

                    $setPolicyCommand += $addKeys;

                }

                if($accessPolicy.permissions.secrets)

                {

                    $addSecrets = "-PermissionsToSecrets $($accessPolicy.Permissions.Secrets -join ',')" + ' ';

                    $setPolicyCommand += $addSecrets;

                }
                
                if($accessPolicy.permissions.certificates)

                {

                    $addCertificates = "-PermissionsToCertificates $($accessPolicy.Permissions.Certificates -join ',')" + ' ';

                    $setPolicyCommand += $addCertificates;

                }
                
                if($accessPolicy.permissions.storage)

                {

                    $addStorage = "-PermissionsToStorage $($accessPolicy.Permissions.Storage -join ',')" + ' ';

                    $setPolicyCommand += $addStorage;

                }

                $setPolicyCommand += ';';

                Invoke-Expression -Command $setPolicyCommand;

                $i++;

                Write-Progress -Activity "Copying access policies from $($BEKvaultres.Name) to $script:secondaryBEKVault" -status "Access Policy $i of $( $BEKvaultres.Properties.AccessPolicies.Count)" -percentComplete ($i / $BEKvaultres.Properties.AccessPolicies.Count*100)

            }

        }

    }

}