param(
    [string] $UserName = "",                 # Azure user account's Email-id
    [string] $Password = "",                                      # Azure user account's Password


    [string] $ResourceGroupName = "siterecoveryprod1",           # Name of the resource group in which our site recovery vault is created
    [string] $SubscriptionName = "DR Hybrid Application Scenarios",                       # Subscription Name where our vault is created
    [string] $VaultName = "b2aRSvaultprod17012017",                # Name of the site recovery vault to which our VMM server is registered                                
	[string] $VaultGeo  = "westus",
    [string] $OutputPathForSettingsFile = "D:\vaults",                    # Location where vault settings file is to be downloaded (to be used for Importing vault settings)
    [string] $PrimaryCloudName = "B2ASiteJun7",
    [string] $ProtectionProfileName = "pptestJun7",            # Name of the protection profile that you want to create
    [string] $VMName = "VM1Jun7",                                           # VM on which all the operations will be triggered (VM should already be created and assigned to cloud on VMM)
    [string] $StorageAccountID = "/subscriptions/c183865e-6077-46f2-a3b1-deb0f4f4650a/resourceGroups/siterecoveryprod1/providers/Microsoft.Storage/storageAccounts/storavrai",
    [string] $AzureNetworkID = "/subscriptions/c183865e-6077-46f2-a3b1-deb0f4f4650a/resourceGroups/siterecoveryProd1/providers/Microsoft.Network/virtualNetworks/vnetavrai",
    [string] $subnet ="Subnet1",
    [string] $OSDiskName = "VM1Jun7",
    [string] $AzureSubnetName = "Subnet1",
    [string] $RPName = "RPtestb2abvtjun7",
    [string] $path = "D:\vaults\test0117.json",
    [string] $VMNameListString = "VM1Jun7:VM2Jun7",
    [string] $OSDiskNameListString = "VM1Jun7:VM2Jun7",
    [int] $JobQueryWaitTimeInSeconds = 60,                                 # Seconds to sleep b/w two calls to check the status of a job completion.

    [bool] $ifCreatePP = $true,
    [bool] $ifPairCloud = $true,
    [bool] $ifEnableDR = $true,

    [bool] $ifDoTFO = $true,
    [bool] $ifDoPFO = $true,
    [bool] $ifDoPFOCommit = $true,
    [bool] $ifDoFailback = $true,
    [bool] $ifDoFailbackCommit = $true,
    [bool] $ifDoFailbackRR = $true,
    [bool] $ifDoUFO = $true,
    [bool] $ifDoUPFOCommit = $true,
    [bool] $ifDoFailbackafterUPFO = $true,
    [bool] $ifDoFailbackCommitwithUPFO = $true,
    [bool] $ifDoFailbackRRafterUPFO = $true,
    [bool] $ifCreateRP = $true,
    [bool] $ifUpdateRP = $true,
    [bool] $ifDoRPTFO = $true,
    [bool] $ifDoRPPFO = $true,
    [bool] $ifDoRPPFOCommit = $true,
    [bool] $ifDoRPFailback = $true,
    [bool] $ifDoRPFailbackCommit = $true,
    [bool] $ifDoRPFailbackRR = $true,
    [bool] $ifDoRPUFO = $true,
    [bool] $ifDoRPUPFOCommit = $true,
    [bool] $ifDoRemoveRP = $true

)

Function global:WaitForJobCompletion
{ 
	param(
        [string] $JobId,
        [int] $JobQueryWaitTimeInSeconds = 60,
        [string] $Message = "NA"
        )
        $isJobLeftForProcessing = $true;
        do
        {
            $Job = Get-AzureRmRecoveryServicesAsrJob -Name $JobId
            Write-Host $("Job Status:") -ForegroundColor Green
            $Job

            if($Job.State -eq "InProgress" -or $Job.State -eq "NotStarted")
            {
	            $isJobLeftForProcessing = $true
            }
            else
            {
                $isJobLeftForProcessing = $false
            }

            if($isJobLeftForProcessing)
	        {
                if($Message -ne "NA")
                {
                    Write-Host $Message -ForegroundColor Yellow
                }
                else
                {
                    Write-Host $($($Job.JobType) + " in Progress...") -ForegroundColor Yellow
                }
		        Write-Host $("Waiting for: " + $JobQueryWaitTimeInSeconds.ToString() + " Seconds") -ForegroundColor Yellow
		        Start-Sleep -Seconds $JobQueryWaitTimeInSeconds
	        }
        }While($isJobLeftForProcessing)
}

Function global:WaitForIRCompletion
{ 
	param(
        [PSObject] $VM,
        [int] $JobQueryWaitTimeInSeconds = 60
        )
        $isProcessingLeft = $true
        $IRjobs = $null

        Write-Host $("IR in Progress...") -ForegroundColor Yellow
        do
        {
            $IRjobs = Get-AzureRmRecoveryServicesAsrJob -TargetObjectId $VM.Name | Sort-Object StartTime -Descending | select -First 5 | Where-Object{$_.JobType -eq "IrCompletion"}
            if($IRjobs -eq $null -or $IRjobs.Count -ne 1)
            {
	            $isProcessingLeft = $true
            }
            else
            {
                $isProcessingLeft = $false
            }

            if($isProcessingLeft)
	        {
                Write-Host $("IR in Progress...") -ForegroundColor Yellow
		        Write-Host $("Waiting for: " + $JobQueryWaitTimeInSeconds.ToString() + " Seconds") -ForegroundColor Yellow
		        Start-Sleep -Seconds $JobQueryWaitTimeInSeconds
	        }
        }While($isProcessingLeft)

        Write-Host $("Finalize IR jobs:") -ForegroundColor Green
        $IRjobs
        WaitForJobCompletion -JobId $IRjobs[0].Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds -Message $("Finalize IR in Progress...")
}

$errorActionPreference = "Stop"

$VMNameList = $VMNameListString.Split(':')

$OSDiskNameList = $OSDiskNameListString.Split(':')

# Add Azure Account
$SecurePassword = ConvertTo-SecureString -AsPlainText $Password -Force
$AzureOrgIdCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword
Add-AzureRmEnvironment -Name dogfood `
    -PublishSettingsFileUrl 'https://windows.azure-test.net/publishsettings/index' `
    -ServiceEndpoint 'https://management-preview.core.windows-int.net/' `
    -ManagementPortalUrl 'https://windows.azure-test.net/' `
    -ActiveDirectoryEndpoint 'https://login.windows-ppe.net/' `
    -ActiveDirectoryServiceEndpointResourceId 'https://management.core.windows.net/' `
    -ResourceManagerEndpoint 'https://api-dogfood.resources.windows-int.net/' `
    -GalleryEndpoint 'https://df.gallery.azure-test.net/' `
    -GraphEndpoint 'https://graph.ppe.windows.net/'

$dogfood = Get-AzureRmEnvironment -Name dogfood
Login-AzureRmAccount #-Environment $dogfood # -Credential $AzureOrgIdCredential #-Tenant $Tenant
#Login-AzureRmAccount -Environment $dogfood -Credential $AzureOrgIdCredential -Tenant "fc6de48d-4b1f-44ff-8e68-8c5a518990b6"
Write-Host $("****************Azure Account Set****************") -ForegroundColor Green

# Set Subscription Context
Select-AzureRmSubscription -SubscriptionName $SubscriptionName
Get-AzureRMContext

# OneTime jobs for Creation of Vault and site
New-AzureRMResourceGroup -Location $VaultGeo -Name $ResourceGroupName
#Register-AzureRMProvider -ProviderNamespace Microsoft.SiteRecovery
New-AzureRMRecoveryServicesVault -Name $VaultName -ResourceGroupName $ResourceGroupName -Location $VaultGeo
#New-AzureRmRecoveryServicesAsrSite -Name $PrimaryCloudName
#$site = Get-AzureRmRecoveryServicesAsrSite -Name $PrimaryCloudName
#Get-AzureRMRecoveryServicesVaultSettingsFile -Vault $Vault -Path $OutputPathForSettingsFile -SiteInternalIdentifier $site.InternalIdentifier -SiteFriendlyName $site.FriendlyName # Downloads Site's settings file


# Set Vault Context
$Vault = Get-AzureRMRecoveryServicesVault -ResourceGroupName $ResourceGroupName | where { $_.Name -eq $VaultName}
$VaultSetingsFile = Get-AzureRMRecoveryServicesVaultSettingsFile -Vault $Vault -Path $OutputPathForSettingsFile
Write-Host $("****************Vault setting file path: " + $VaultSetingsFile.FilePath + "****************") -ForegroundColor Green

Import-AzureRmRecoveryServicesAsrVaultSettingsFile -Path $VaultSetingsFile.FilePath -ErrorAction Stop
Write-Host $("****************Vault Context set for vault: " + $VaultName + "****************") -ForegroundColor Green

 $currentJob = New-AzureRmRecoveryServicesAsrFabric -Name $PrimaryCloudName
 $currentJob
 WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds

$site = Get-AzureRmRecoveryServicesAsrFabric -Name $PrimaryCloudName

#Get-AzureRMRecoveryServicesVaultSettingsFile -Vault $Vault -Path $OutputPathForSettingsFile -SiteIdentifier $site.SiteIdentifier -SiteFriendlyName $site.FriendlyName # Downloads Site's settings file

$siteSetingsFile = Get-AzureRMRecoveryServicesVaultSettingsFile -Vault $Vault -Path $OutputPathForSettingsFile -SiteIdentifier $site.SiteIdentifier -SiteFriendlyName $site.FriendlyName 
$siteSetingsFile.FilePath

Stop-Service dra -Force
Start-Sleep -s 30
cd 'C:\Program Files\Microsoft Azure Site Recovery Provider'
.\DRConfigurator.exe /r /Credentials $siteSetingsFile.FilePath /friendlyname mukeshk-kvm4
cd C:\Users\administrator
Start-Service dra
Start-Sleep -s 60
 

# Enumerate registered servers
Get-AzureRmRecoveryServicesAsrFabric | Get-AzureRmRecoveryServicesAsrServicesProvider
Write-Host $("****************Fetched registered servers to vault****************") -ForegroundColor Green

Start-Sleep -s 60

# Get Protection containers
$ProtectionContainers = Get-AzureRmRecoveryServicesAsrFabric | Get-AzureRmRecoveryServicesAsrProtectionContainer
$PrimaryContainer = $ProtectionContainers | where { $_.FriendlyName -eq $PrimaryCloudName }
Write-Host $("Primary Cloud:") -ForegroundColor Green
$PrimaryContainer
Write-Host $("****************Clouds fetched before Pairing****************") -ForegroundColor Green


# Create Protection Profile
if($ifCreatePP)
{
    Write-Host $("Creating Protection Profile") -ForegroundColor Green
    $currentJob = New-AzureRmRecoveryServicesAsrPolicy -Name $ProtectionProfileName -ReplicationProvider HyperVReplicaAzure -ReplicationFrequencyInSeconds 30 -RecoveryPoints 1 -ApplicationConsistentSnapshotFrequencyInHours 0 -RecoveryAzureStorageAccountId $StorageAccountID -Encryption Disable
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    $ProtectionProfile = Get-AzureRmRecoveryServicesAsrPolicy -Name $ProtectionProfileName
    $ProtectionProfile
    Write-Host $("****************Created Protection Profile****************") -ForegroundColor Green
}

$ProtectionProfile = Get-AzureRmRecoveryServicesAsrPolicy -Name $ProtectionProfileName
$ProtectionProfile
# Cloud Pairing (Associate Cloud with Protection Profile)
if($ifPairCloud)
{
    Write-Host $("Started Cloud Pairing") -ForegroundColor Green
    $currentJob = New-AzureRmRecoveryServicesAsrProtectionContainerMapping -Name $($PrimaryCloudName + $ProtectionProfileName) -Policy $ProtectionProfile -PrimaryProtectionContainer $PrimaryContainer
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************Clouds paired****************") -ForegroundColor Green
}

# Update Protection container objects after cloud pairing

$ProtectionContainers = Get-AzureRmRecoveryServicesAsrFabric | Get-AzureRmRecoveryServicesAsrProtectionContainer
$PrimaryContainer = $ProtectionContainers | where { $_.FriendlyName -eq $PrimaryCloudName }
Write-Host $("Primary Cloud:") -ForegroundColor Green
$PrimaryContainer
Write-Host $("****************Clouds fetched after Pairing****************") -ForegroundColor Green
$ProtectionContainerMapping = Get-AzureRmRecoveryServicesAsrProtectionContainerMapping -Name $($PrimaryCloudName + $ProtectionProfileName) -ProtectionContainer $PrimaryContainer
$ProtectionContainerMapping
# Get Policy to enable protection
$ProtectionProfile = Get-AzureRmRecoveryServicesAsrPolicy -Name $ProtectionProfileName
$ProtectionProfile

# Get VM to enable protection
$VM = Get-AzureRmRecoveryServicesAsrProtectableItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Write-Host $("****************VM fetched for Enabling Protection****************") -ForegroundColor Green

<#
Remove-AzureRmRecoveryServicesAsrReplicationProtectedItem -ReplicationProtectedItem $VM -Force
#>

# Enable Protection

#if($ifEnableDR)
#{
#    Write-Host $("Started Enable Protection") -ForegroundColor Green
#    $currentJob = Set-AzureRmRecoveryServicesAsrProtectionEntity -ProtectionEntity $VM -Protection Enable -Force -Policy $ProtectionProfile -RecoveryAzureStorageAccountId $StorageAccountID -OSDiskName $OSDiskName -OS Windows
#    #$currentJob = Set-AzureRmRecoveryServicesAsrProtectionEntity -ProtectionEntity $VM -Protection Enable -Force -Policy $ProtectionProfile -RecoveryAzureStorageAccountId $StorageAccountID
#   $currentJob
#    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
#    #Start-Sleep -s 180
#    WaitForIRCompletion -VM $VM -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
#    Write-Host $("****************Protection Enabled for VM****************") -ForegroundColor Green
#}


$VMList = Get-AzureRmRecoveryServicesAsrProtectableItem -ProtectionContainer $PrimaryContainer  

# Enable Protection
if($ifEnableDR)
{
    for($i = 0; $i -lt $VMNameList.Count ; $i++)
    {
        $VM = $VMList | where { $_.FriendlyName -eq $VMNameList[$i] }
        Write-Host $("Started Enable Protection") -ForegroundColor Green
        $currentJob = New-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectableItem $VM -Name $VM.Name -ProtectionContainerMapping $ProtectionContainerMapping -RecoveryAzureStorageAccountId $StorageAccountID -OSDiskName $OSDiskNameList[$i] -OS Windows -RecoveryResourceGroupId "/subscriptions/c183865e-6077-46f2-a3b1-deb0f4f4650a/resourceGroups/siterecoveryprod1"
        $currentJob
        WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
        WaitForIRCompletion -VM $VM -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
        Write-Host $("****************Protection Enabled for VM****************") -ForegroundColor Green
    }
}

<#
# Get VM to enable protection
$VM = Get-AzureRmRecoveryServicesAsrProtectableItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
$currentJob = New-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectableItem $VM -Name $VM.Name -ProtectionContainerMapping $ProtectionContainerMapping -RecoveryAzureStorageAccountId $StorageAccountID -OSDiskName $OSDiskName -OS Windows
$currentJob

#>

# Get protected VM
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Write-Host $("****************VM fetched after Enabling Protection****************") -ForegroundColor Green

net stop dra
Start-Sleep -s 90
net start dra
Start-Sleep -s 180

$vList = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer
# Get protected VM
for($i = 0; $i -lt $VMNameList.Count ; $i++)
{   
    $v = $vList | where { $_.FriendlyName -eq $VMNameList[$i] }
    $v
    $v.NicDetailsList[0]
    $v.NicDetailsList[0].NicId
    $currentJob = Set-AzureRmRecoveryServicesAsrReplicationProtectedItem -ReplicationProtectedItem $v -PrimaryNic $v.NicDetailsList[0].NicId -RecoveryNetworkId $AzureNetworkID -RecoveryNicSubnetName $subnet
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds

}
<#
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
    $VM.NicDetailsList[0]
    $VM.NicDetailsList[0].NicId
    $currentJob = Set-AzureRmRecoveryServicesAsrReplicationProtectedItem -ReplicationProtectedItem $VM -PrimaryNic $VM.NicDetailsList[0].NicId -RecoveryNetworkId $AzureNetworkID -RecoveryNicSubnetName $subnet
    $currentJob
#>


$vList = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer
for($i = 0; $i -lt $VMNameList.Count ; $i++)
{   
    $v = $vList | where { $_.FriendlyName -eq $VMNameList[$i] }
    $v
    $v.NicDetailsList[0]
    $v.NicDetailsList[0].NicId
}


#$v = Get-AzureRmRecoveryServicesAsrVM -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
#$v = Get-AzureRmRecoveryServicesAsrVM -ProtectionContainer $PrimaryContainer -Name e5f52dde-53cd-4ae4-8299-7e117cc8da44
#$v
#$v.NicDetailsList[0]
#$v.NicDetailsList[0].NicId
#Set-AzureRmRecoveryServicesAsrVM -VirtualMachine $v -PrimaryNic $v.NicDetailsList[0].NicId -RecoveryNetworkId $AzureNetworkID -RecoveryNicSubnetName $subnet
#Start-Sleep -s 60
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM

# Start TFO
if($ifDoTFO)
{
    Write-Host $("Triggered TFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrTestFailoverJob -ReplicationProtectedItem $VM -Direction PrimaryToRecovery -AzureVMNetworkId $AzureNetworkID
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************TFO Started for VM****************") -ForegroundColor Green
    Start-Sleep -s 100
    # Complete TFO
    Write-Host $("Started TFO Completion") -ForegroundColor Green
    $currentJob = Resume-AzureRmRecoveryServicesAsrJob -Name $currentJob.Name
    $currentJob
    Start-Sleep -s 30
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************TFO Completed for VM****************") -ForegroundColor Green
}

start-Sleep -s 180

# Planned Failover
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM

if($ifDoPFO)
{
    Write-Host $("Triggering PFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrPlannedFailoverJob -ReplicationProtectedItem $VM -Direction PrimaryToRecovery
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************PFO finished for VM****************") -ForegroundColor Green
}
start-Sleep -s 100
# Commit after PFO

$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Write-Host $("****************VM fetched after Planned Failover****************") -ForegroundColor Green

if($ifDoPFOCommit)
{
    Write-Host $("Triggering Commit after PFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrCommitFailoverJob -ReplicationProtectedItem $VM
    #-Direction PrimaryToRecovery
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Commit after PFO finished for VM***********") -ForegroundColor Green
}

# Planned Failback
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM

if($ifDoFailback)
{
    Write-Host $("Triggering Planned Failback") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrPlannedFailoverJob -ReplicationProtectedItem $VM -Direction RecoveryToPrimary
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************Failback finished for VM****************") -ForegroundColor Green
}

start-Sleep -s 100

# Commit after Planned Failback
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Write-Host $("****************VM fetched after Planned Failback****************") -ForegroundColor Green

if($ifDoFailbackCommit)
{
    Write-Host $("Triggering Commit after PFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrCommitFailoverJob -ReplicationProtectedItem $VM
    #-Direction RecoveryToPrimary
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Commit after Planned Failback finished for VM***********") -ForegroundColor Green
}

# Reverse Replication after Planned Failback
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Write-Host $("****************VM fetched after Commit****************") -ForegroundColor Green

if($ifDoFailbackRR)
{
    Write-Host $("Triggering Reverse Replication") -ForegroundColor Green
    $currentJob = Update-AzureRmRecoveryServicesAsrProtectionDirection -ReplicationProtectedItem $VM -Direction PrimaryToRecovery
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    WaitForIRCompletion -VM $VM -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Reverse Replication finished for VM***********") -ForegroundColor Green
}
Start-Sleep -s 160
# Unplanned Failover
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM

if($ifDoUFO)
{
    Write-Host $("Triggering UFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrUnplannedFailoverJob -ReplicationProtectedItem $VM -Direction PrimaryToRecovery
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************UFO finished for VM****************") -ForegroundColor Green
}

start-Sleep -s 100

# Commit after UnPFO

$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Write-Host $("****************VM fetched after Planned Failover****************") -ForegroundColor Green

if($ifDoUPFOCommit)
{
    Write-Host $("Triggering Commit after UPFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrCommitFailoverJob -ReplicationProtectedItem $VM 
    #-Direction PrimaryToRecovery
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Commit after UPFO finished for VM***********") -ForegroundColor Green
}

# Planned Failback
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM

if($ifDoFailbackafterUPFO)
{
    Write-Host $("Triggering Planned Failback after UPFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrPlannedFailoverJob -ReplicationProtectedItem $VM -Direction RecoveryToPrimary
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************Failback finished for VM after UNplanned failover****************") -ForegroundColor Green
}

start-Sleep -s 100

# Commit after Planned Failback
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Write-Host $("****************VM fetched after Planned Failback after upfo****************") -ForegroundColor Green

if($ifDoFailbackCommitwithUPFO)
{
    Write-Host $("Triggering failbackCommit after UPFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrCommitFailoverJob -ReplicationProtectedItem $VM
    #-Direction RecoveryToPrimary
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Commit after Planned Failback finished for VM***********") -ForegroundColor Green
}

# Reverse Replication after Planned Failback
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Write-Host $("****************VM fetched after Commit****************") -ForegroundColor Green

if($ifDoFailbackRRafterUPFO)
{
    Write-Host $("Triggering Reverse Replication") -ForegroundColor Green
    $currentJob = Update-AzureRmRecoveryServicesAsrProtectionDirection -ReplicationProtectedItem $VM -Direction PrimaryToRecovery
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    WaitForIRCompletion -VM $VM -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Reverse Replication finished for VM***********") -ForegroundColor Green
}

$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Start-Sleep -s 80
Stop-VM -Name $VMName -Force
$VMList = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer
if($ifCreateRP)
{
    $site = Get-AzureRmRecoveryServicesAsrFabric -Name $PrimaryCloudName
    Write-Host $("Triggered Create RP") -ForegroundColor Green

    $VM = $VMList | where { $_.FriendlyName -eq $VMNameList[0] }

    $currentJob = New-AzureRmRecoveryServicesAsrRecoveryPlan -Name $RPName -PrimaryFabric $site -Azure -FailoverDeploymentModel ResourceManager -ReplicationProtectedItem $VM
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    $RP = Get-AzureRmRecoveryServicesAsrRecoveryPlan -Name $RPName
    $RP
    Write-Host $("****************RP Created****************") -ForegroundColor Green
}


$RP = Get-AzureRmRecoveryServicesAsrRecoveryPlan -Name $RPName -Path $path
if($ifUpdateRP)
{

    $RP = Edit-AzureRmRecoveryServicesAsrRecoveryPlan -RecoveryPlan $RP -AppendGroup

    $VM = $VMList | where { $_.FriendlyName -eq $VMNameList[1] }
	#-or  $_.FriendlyName -eq $VMNameList[2]}

    $RP = Edit-AzureRmRecoveryServicesAsrRecoveryPlan -RecoveryPlan $RP -Group $RP.Groups[3] -AddProtectedItems $VM
    $RP.Groups

    Write-Host $("Triggered Update RP") -ForegroundColor Green
    $currentJob = Update-AzureRmRecoveryServicesAsrRecoveryPlan -RecoveryPlan $RP
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************RP Updated****************") -ForegroundColor Green
}

$RP = Get-AzureRmRecoveryServicesAsrRecoveryPlan -Name $RPName
$RP.Groups

# Start TFO
if($ifDoRPTFO)
{
    Write-Host $("Triggered TFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrTestFailoverJob -RecoveryPlan $RP -Direction PrimaryToRecovery -AzureVMNetworkId $AzureNetworkID
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************TFO Started for VM****************") -ForegroundColor Green

    # Complete TFO
    Write-Host $("Started TFO Completion") -ForegroundColor Green
    $currentJob = Resume-AzureRmRecoveryServicesAsrJob -Name $currentJob.Name
    $currentJob
    Start-Sleep -s 60
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************TFO Completed for VM****************") -ForegroundColor Green
}

# Planned Failover
$RP = Get-AzureRmRecoveryServicesAsrRecoveryPlan -Name $RPName 
Write-Host $("RP:") -ForegroundColor Green
$RP

if($ifDoRPPFO)
{
    Write-Host $("Triggering PFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrPlannedFailoverJob -RecoveryPlan $RP -Direction PrimaryToRecovery
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************PFO finished for VM****************") -ForegroundColor Green
}
start-Sleep -s 100

# Commit after PFO
$RP = Get-AzureRmRecoveryServicesAsrRecoveryPlan -Name $RPName 
Write-Host $("RP:") -ForegroundColor Green
$RP
Write-Host $("****************VM fetched after Planned Failover****************") -ForegroundColor Green

if($ifDoRPPFOCommit)
{
    Write-Host $("Triggering Commit after PFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrCommitFailoverJob -RecoveryPlan $RP
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Commit after PFO finished for VM***********") -ForegroundColor Green
}

# Planned Failback
$RP = Get-AzureRmRecoveryServicesAsrRecoveryPlan -Name $RPName 
Write-Host $("RP:") -ForegroundColor Green
$RP

if($ifDoRPFailback)
{
    Write-Host $("Triggering Planned Failback") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrPlannedFailoverJob -RecoveryPlan $RP -Direction RecoveryToPrimary
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************Failback finished for VM****************") -ForegroundColor Green
}
start-Sleep -s 100

# Commit after Planned Failback
$RP = Get-AzureRmRecoveryServicesAsrRecoveryPlan -Name $RPName 
Write-Host $("RP:") -ForegroundColor Green
$RP
Write-Host $("****************VM fetched after Planned Failback****************") -ForegroundColor Green

if($ifDoRPFailbackCommit)
{
    Write-Host $("Triggering Commit after PFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrCommitFailoverJob -RecoveryPlan $RP
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Commit after Planned Failback finished for VM***********") -ForegroundColor Green
}

# Reverse Replication after Planned Failback
$RP = Get-AzureRmRecoveryServicesAsrRecoveryPlan -Name $RPName 
Write-Host $("RP:") -ForegroundColor Green
$RP
Write-Host $("****************VM fetched after Commit****************") -ForegroundColor Green

if($ifDoRPFailbackRR)
{
    Write-Host $("Triggering Reverse Replication") -ForegroundColor Green
    $currentJob = Update-AzureRmRecoveryServicesAsrProtectionDirection -RecoveryPlan $RP -Direction PrimaryToRecovery 
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Reverse Replication finished for VM***********") -ForegroundColor Green
}
Start-Sleep -s 160
# Unplanned Failover
$RP = Get-AzureRmRecoveryServicesAsrRecoveryPlan -Name $RPName 
Write-Host $("RP:") -ForegroundColor Green
$RP

# Unplanned Failover
if($ifDoRPUFO)
{
    Write-Host $("Triggering UFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrUnplannedFailoverJob -RecoveryPlan $RP -Direction PrimaryToRecovery -PerformSourceSideActions
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************UFO finished for VM****************") -ForegroundColor Green
}

$RP = Get-AzureRmRecoveryServicesAsrRecoveryPlan -Name $RPName 
Write-Host $("RP:") -ForegroundColor Green
$RP
start-Sleep -s 100

if($ifDoRPUPFOCommit)
{
    Write-Host $("Triggering Commit after PFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrCommitFailoverJob -RecoveryPlan $RP
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Commit after PFO finished for VM***********") -ForegroundColor Green
}
$RP = Get-AzureRmRecoveryServicesAsrRecoveryPlan -Name $RPName 
Write-Host $("RP:") -ForegroundColor Green
$RP

# Remove RP
if($ifDoRemoveRP)
{
    Write-Host $("****************Removing RP****************") -ForegroundColor Green
    $currentJob = Remove-AzureRmRecoveryServicesAsrRecoveryPlan -RecoveryPlan $RP
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************Removed RP****************") -ForegroundColor Green
}
$VMList = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer
# Disable Protection
Write-Host $("Started Disable Protection") -ForegroundColor Green
#$currentJob = Set-AzureRmRecoveryServicesAsrProtectionEntity -ProtectionEntity $VM -Protection Disable -force
#$currentJob
#WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
#Write-Host $("****************Disabled Protection for VM****************") -ForegroundColor Green
for($i = 0; $i -lt $VMNameList.Count ; $i++)
{
    $VM = $VMList | where { $_.FriendlyName -eq $VMNameList[$i] }
    Write-Host $("Started Disable Protection") -ForegroundColor Green
    $currentJob = Remove-AzureRmRecoveryServicesAsrReplicationProtectedItem -ReplicationProtectedItem $VM -Force
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************Disable DR finished for VM****************") -ForegroundColor Green
}

$VM = Get-AzureRmRecoveryServicesAsrProtectableItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Write-Host $("****************VM fetched after Disable Protection****************") -ForegroundColor Green

# Unpair Cloud
Write-Host $("Started Cloud Unpairing") -ForegroundColor Green
$currentJob = Remove-AzureRmRecoveryServicesAsrProtectionContainerMapping -ProtectionContainerMapping $ProtectionContainerMapping
$currentJob
WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
Write-Host $("****************Clouds Unpaired****************") -ForegroundColor Green

# Remove Protection Profile
Write-Host $("Started Protection Profile removal") -ForegroundColor Green
$currentJob = Remove-AzureRmRecoveryServicesAsrPolicy -Policy $ProtectionProfile
$currentJob
WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
Write-Host $("****************Removed Protection Profile:****************") -ForegroundColor Green

#Remove Server
$server = Get-AzureRmRecoveryServicesAsrFabric | Get-AzureRmRecoveryServicesAsrServicesProvider
Write-Host $("Started Registered server removal") -ForegroundColor Green
$currentJob = Remove-AzureRmRecoveryServicesAsrServicesProvider -ServicesProvider $server
$currentJob
WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
Write-Host $("****************Unregistered server:****************") -ForegroundColor Green

#Remove Site
$site = Get-AzureRmRecoveryServicesAsrFabric -Name $PrimaryCloudName
Write-Host $("Started site removal") -ForegroundColor Green
$currentJob = Remove-AzureRmRecoveryServicesAsrFabric -Fabric $site
$currentJob
WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
Write-Host $("****************Site removal successful****************") -ForegroundColor Green

