param(

    [string] $UserName = "",                 # Azure user account's Email-id
    [string] $Password = '',                                      # Azure user account's Password
    [string] $ResourceGroupName = "siterecoveryprod1",           # Name of the resource group in which our site recovery vault is created
    #[string] $ResourceGroupName = "rgbrs1",
    [string] $SubscriptionName = "DR Hybrid Application Scenarios",                       # Subscription Name where our vault is created
    [string] $VaultName = "b2aRSvaultprod17012017",                # Name of the site recovery vault to which our VMM server is registered
	#[string] $VaultGeo  = "South Central US",                                  
	[string] $VaultGeo  = "westus",
    #[string] $VaultGeo  = "Brazil South",
    [string] $PrimaryFabricName = "CP-B3L30107-23.ntdev.corp.microsoft.com",                       
    [string] $RecoveryFabricName = "CP-B3L40104-01.ntdev.corp.microsoft.com",  
    [string] $OutputPathForSettingsFile = "D:\vaults",                    # Location where vault settings file is to be downloaded (to be used for Importing vault settings)
    [string] $PrimaryCloudName = "E2ECloudProdJun08",
    [string] $RecoveryCloudName = "E2ERProdJun08",
    [string] $ProtectionProfileName = "PPJun8",            # Name of the protection profile that you want to create
    [string] $VMName = "VM1Jun8",  
    #[string] $VMName = "win2k12r2",                                     # VM on which all the operations will be triggered (VM should already be created and assigned to cloud on VMM)
    [string] $PrimaryNetworkFriendlyName = "corp", # Primary Network Friendly Name
    [string] $RecoveryNetworkFriendlyName = "corp", # Recovery Network Friendly Name
    [string] $testRecoveryNetworkFriendlyName ="VSwitch_VLan",
    [string] $OSDiskName = "VM1Jun8",
    [string] $machineUserName = "",
    [string] $machinePassword = '',
    [int] $JobQueryWaitTimeInSeconds = 60,                                 # Seconds to sleep b/w two calls to check the status of a job completion.
    [string] $VMNameListString = "VM1Jun8:VM2Jun8",
    [string] $RPName = "RPteste2jun8",
    [string] $path = "D:\vaults\testA11.json",
    [bool] $ifCreatePP = $true,
    [bool] $ifPairCloud = $true,
    [bool] $ifEnableDR = $true,
    [bool] $ifMapNetwork = $true,

    [bool] $ifDoTFO = $true,
    [bool] $ifDoPFO = $true,
    [bool] $ifDoPFOCommit = $true,
    [bool] $ifDoPFORR = $true,
    [bool] $ifDoFailback = $true,
    [bool] $ifDoFailbackCommit = $true,
    [bool] $ifDoFailbackRR = $true,
    [bool] $ifDoUFO = $true,
    [bool] $ifDoUPFOCommit = $true,
    [bool] $ifDoUPFORR = $true,
    [bool] $ifDoFailbackafterUPFO = $true,
    [bool] $ifDoFailbackCommitwithUPFO = $true,
    [bool] $ifDoFailbackRRafterUPFO = $true,
    [bool] $ifCreateRP = $true,
    [bool] $ifUpdateRP = $true,
    [bool] $ifDoRPTFO = $true,
    [bool] $ifDoRPPFO = $true,
    [bool] $ifDoRPPFOCommit = $true,
    [bool] $ifDoRPPFORR = $true,
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
            $IRjobs = Get-AzureRmRecoveryServicesAsrJob -TargetObjectId $VM.Name | Sort-Object StartTime -Descending | select -First 4 | Where-Object{$_.JobType -eq "PrimaryIrCompletion" -or $_.JobType -eq "SecondaryIrCompletion"}
            if($IRjobs -eq $null -or $IRjobs.Count -lt 2)
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
        WaitForJobCompletion -JobId $IRjobs[1].Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds -Message $("Finalize IR in Progress...")
}

Function global:WaitForVMNicUpdate
{ 
	param(
        [PSObject] $VM,
        [int] $JobQueryWaitTimeInSeconds = 60
        )
        $isProcessingLeft = $true
        $Nicjobs = $null

        Write-Host $("Waiting for VMNicUpdate...") -ForegroundColor Yellow
        do
        {
            $Nicjobs = Get-AzureRmRecoveryServicesAsrJob | Sort-Object StartTime -Descending | select -First 5 | Where-Object{$_.JobType -eq "VMNicUpdate"}
            if($Nicjobs -eq $null -or $Nicjobs.Count -lt 1)
            {
	            $isProcessingLeft = $true
            }
            else
            {
                $isProcessingLeft = $false
            }

            if($isProcessingLeft)
	        {
                Write-Host $("Waiting for VMNicUpdate...") -ForegroundColor Yellow
		        Write-Host $("Waiting for: " + $JobQueryWaitTimeInSeconds.ToString() + " Seconds") -ForegroundColor Yellow
		        Start-Sleep -Seconds $JobQueryWaitTimeInSeconds
	        }
        }While($isProcessingLeft)

        Write-Host $("VMNicUpdate job:") -ForegroundColor Green
        $Nicjobs
        WaitForJobCompletion -JobId $Nicjobs[0].Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
}

$StopOnPremVMScriptBlock = {
		param(
			[parameter(Mandatory=$True)][string] $VmName
		)
		Stop-SCVirtualMachine -VM $vmName -Force 
		
	}
$DRARegisterBlock = {
		param(
			[parameter(Mandatory=$True)][string] $VaultSettingFilePath
		)
		cd 'C:\Program Files\Microsoft System Center 2012 R2\Virtual Machine Manager\bin'
       .\DRConfigurator.exe /r /Credentials $VaultSettingFilePath /friendlyname $RecoveryFabricName /startvmmservice
		
	}

$errorActionPreference = "Stop"

$VMNameList = $VMNameListString.Split(':')

$machineSecurePassword = ConvertTo-SecureString -AsPlainText $machinePassword -Force
$Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $machineUserName, $machineSecurePassword

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

#Import-AzureRmContext -Path C:\Users\avrai\Desktop\Scripts\2016-08-10\RecoveryServices.SiteRecovery\Scripts\c183865e-6077-46f2-a3b1-deb0f4f4650a

Login-AzureRmAccount #-Environment $dogfood # -Credential $AzureOrgIdCredential
Write-Host $("****************Azure Account Set****************") -ForegroundColor Green

# Set Subscription Context
#$context = Get-AzureRmContext
Select-AzureRmSubscription -SubscriptionName $SubscriptionName #-TenantId $context.Tenant.TenantId 
#Write-Host $("****************Selected Subscription: " + $SubscriptionId + "****************")  -ForegroundColor Green
#Get-AzureRmContext

# OneTime jobs for Creation of Vault and site
#New-AzureRMResourceGroup -Location $VaultGeo -Name $ResourceGroupName
#Register-AzureRMProvider -ProviderNamespace Microsoft.SiteRecovery

#New-AzureRMRecoveryServicesVault -Name $VaultName -ResourceGroupName $ResourceGroupName -Location $VaultGeo

# Set Vault Context
$Vault = Get-AzureRMRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName
$VaultSetingsFile = Get-AzureRMRecoveryServicesVaultSettingsFile -Vault $Vault -Path $OutputPathForSettingsFile
Write-Host $("****************Vault setting file path: " + $VaultSetingsFile.FilePath + "****************") -ForegroundColor Green

Import-AzureRmRecoveryServicesAsrVaultSettingsFile -Path $VaultSetingsFile.FilePath -ErrorAction Stop
Write-Host $("****************Vault Context set for vault: " + $VaultName + "****************") -ForegroundColor Green

$VaultSettingFilePath = $VaultSetingsFile.FilePath


cd 'C:\Program Files\Microsoft System Center 2012 R2\Virtual Machine Manager\bin'
.\DRConfigurator.exe /r /Credentials $VaultSettingFilePath /friendlyname $PrimaryFabricName /startvmmservice
cd 'C:\Users\administrator'
cp $VaultSettingFilePath \\CP-B3L40104-01\vaults
Start-Sleep -s 30
Invoke-Command -ComputerName 'CP-B3L40104-01.ntdev.corp.microsoft.com' -Credential $Credential -ScriptBlock $DRARegisterBlock -ArgumentList $VaultSettingFilePath
Start-Sleep -s 360


# Enumerate registered servers
$Fabrics = Get-AzureRmRecoveryServicesAsrFabric
$PrimaryFabric = $Fabrics | Where-Object { $_.FriendlyName -eq $PrimaryFabricName}
$RecoveryFabric = $Fabrics | Where-Object { $_.FriendlyName -eq $RecoveryFabricName}

Get-AzureRmRecoveryServicesAsrFabric | Get-AzureRmRecoveryServicesAsrServicesProvider
Write-Host $("****************Fetched registered DRAs to vault****************") -ForegroundColor Green

<#
$PSC = Get-AzureRmRecoveryServicesAsrStorageClassification -Name "8891569e-aaef-4a46-a4a0-78c14f2d7b09"
$RSC = Get-AzureRmRecoveryServicesAsrStorageClassification -Name "8891569e-aaef-4a46-a4a0-78c14f2d7b09"
 New-AzureRmRecoveryServicesAsrStorageClassificationMapping -Name testStorageMapping 
#>


# Get Protection containers
$ProtectionContainers = Get-AzureRmRecoveryServicesAsrFabric | Get-AzureRmRecoveryServicesAsrProtectionContainer
$PrimaryContainer = $ProtectionContainers | where { $_.FriendlyName -eq $PrimaryCloudName }
Write-Host $("Primary Cloud:") -ForegroundColor Green
$PrimaryContainer
$RecoveryContainer = $ProtectionContainers | where { $_.FriendlyName-eq $RecoveryCloudName }
Write-Host $("Recovery Cloud:") -ForegroundColor Green
$RecoveryContainer
Write-Host $("****************Clouds fetched before Pairing****************") -ForegroundColor Green

# Create Protection Profile
if($ifCreatePP)
{
    Write-Host $("Creating Protection Profile") -ForegroundColor Green
    $currentJob = New-AzureRmRecoveryServicesAsrPolicy -Name $ProtectionProfileName -ReplicationProvider HyperVReplica2012R2 -ReplicationMethod Online -ReplicationFrequencyInSeconds 30 -RecoveryPoints 1 -ApplicationConsistentSnapshotFrequencyInHours 0 -ReplicationPort 8083 -Authentication Kerberos -ReplicaDeletion Required 
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
    $currentJob = New-AzureRmRecoveryServicesAsrProtectionContainerMapping -Name $($PrimaryCloudName + $ProtectionProfileName + $RecoveryCloudName) -Policy $ProtectionProfile -PrimaryProtectionContainer $PrimaryContainer -RecoveryProtectionContainer $RecoveryContainer
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************Clouds paired****************") -ForegroundColor Green
}


# Update Protection container objects after cloud pairing
$ProtectionContainers = Get-AzureRmRecoveryServicesAsrFabric | Get-AzureRmRecoveryServicesAsrProtectionContainer
$PrimaryContainer = $ProtectionContainers | where { $_.FriendlyName -eq $PrimaryCloudName }
Write-Host $("Primary Cloud:") -ForegroundColor Green
$PrimaryContainer
$RecoveryContainer = $ProtectionContainers | where { $_.FriendlyName-eq $RecoveryCloudName }
Write-Host $("Recovery Cloud:") -ForegroundColor Green
$RecoveryContainer
Write-Host $("****************Clouds fetched after Pairing****************") -ForegroundColor Green
$ProtectionContainerMapping = Get-AzureRmRecoveryServicesAsrProtectionContainerMapping -Name $($PrimaryCloudName + $ProtectionProfileName + $RecoveryCloudName) -ProtectionContainer $PrimaryContainer
$ProtectionContainerMapping
#>
# Get VM to enable protection
$VM = Get-AzureRmRecoveryServicesAsrProtectableItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Write-Host $("****************VM fetched for Enabling Protection****************") -ForegroundColor Green

# Get Policy to enable protection
$ProtectionProfile = Get-AzureRmRecoveryServicesAsrPolicy -Name $ProtectionProfileName
$ProtectionProfile

# Enable Protection
$VMList = Get-AzureRmRecoveryServicesAsrProtectableItem -ProtectionContainer $PrimaryContainer 
if($ifEnableDR)
{
    for($i = 0; $i -lt $VMNameList.Count ; $i++)
    {
        $VM = $VMList | where { $_.FriendlyName -eq $VMNameList[$i] }
        Write-Host $("Started Enable Protection") -ForegroundColor Green
        $currentJob = New-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectableItem $VM -Name $VM.Name -ProtectionContainerMapping $ProtectionContainerMapping
        $currentJob
        WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
        WaitForIRCompletion -VM $VM -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
        Write-Host $("****************Protection Enabled for VM****************") -ForegroundColor Green
    }
}


# Get protected VM
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Write-Host $("****************VM fetched after Enabling Protection****************") -ForegroundColor Green

# Network Mapping
if($ifMapNetwork)
{
    $PrimaryNetwork = Get-AzureRmRecoveryServicesAsrNetwork -Fabric $PrimaryFabric | where { $_.FriendlyName -eq "$PrimaryNetworkFriendlyName"}
    $PrimaryNetwork
    $RecoveryNetwork = Get-AzureRmRecoveryServicesAsrNetwork -Fabric $RecoveryFabric | where { $_.FriendlyName -eq "$RecoveryNetworkFriendlyName"}
    $RecoveryNetwork
    $currentJob = New-AzureRmRecoveryServicesAsrNetworkMapping -Name $($PrimaryNetworkFriendlyName + $RecoveryNetworkFriendlyName + "map") -PrimaryNetwork $PrimaryNetwork -RecoveryNetwork $RecoveryNetwork
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Get-AzureRmRecoveryServicesAsrNetworkMapping -Network $PrimaryNetwork
 
}

$testRecoveryNetwork = Get-AzureRmRecoveryServicesAsrNetwork -Fabric $RecoveryFabric | where { $_.FriendlyName -eq $testRecoveryNetworkFriendlyName}

# Start TFO
if($ifDoTFO)
{
    Write-Host $("Triggered TFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrTestFailoverJob -ReplicationProtectedItem $VM -Direction PrimaryToRecovery -VMNetwork $testRecoveryNetwork
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************TFO Started for VM****************") -ForegroundColor Green
    Start-Sleep -s 60
    # Complete TFO
    Write-Host $("Started TFO Completion") -ForegroundColor Green
    $currentJob = Resume-AzureRmRecoveryServicesAsrJob -Name $currentJob.Name
    $currentJob
    Start-Sleep -s 120
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************TFO Completed for VM****************") -ForegroundColor Green
}
#>
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
#>
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

# Reverse Replication after PFO
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Write-Host $("****************VM fetched after Commit****************") -ForegroundColor Green

if($ifDoPFORR)
{
    Write-Host $("Triggering Reverse Replication") -ForegroundColor Green
    $currentJob = Update-AzureRmRecoveryServicesAsrProtectionDirection -ReplicationProtectedItem $VM -Direction RecoveryToPrimary
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Reverse Replication finished for VM***********") -ForegroundColor Green
}

# Planned Failback
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Invoke-Command -ComputerName 'CP-B3L40104-01.ntdev.corp.microsoft.com' -Credential $Credential -ScriptBlock $StopOnPremVMScriptBlock -ArgumentList $VMName
Start-Sleep -s 30



if($ifDoFailback)
{
    Write-Host $("Triggering Planned Failback") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrPlannedFailoverJob -ReplicationProtectedItem $VM -Direction RecoveryToPrimary
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************Failback finished for VM****************") -ForegroundColor Green
}

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
    Write-Host $("************Reverse Replication finished for VM***********") -ForegroundColor Green
}

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
if($ifDoUPFOCommit)
{
    Write-Host $("Triggering Commit after UPFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrCommitFailoverJob -ReplicationProtectedItem $VM
#-Direction PrimaryToRecovery
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Commit after UPFO finished for VM***********") -ForegroundColor Green
}

# Reverse Replication after UPFO
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Write-Host $("****************VM fetched after Commit****************") -ForegroundColor Green

if($ifDoUPFORR)
{
    Write-Host $("Triggering Reverse Replication after UPFO") -ForegroundColor Green
    $currentJob = Update-AzureRmRecoveryServicesAsrProtectionDirection -ReplicationProtectedItem $VM -Direction RecoveryToPrimary
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Reverse Replication finished for VM after UPFO***********") -ForegroundColor Green
}

# Planned Failback
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Invoke-Command -ComputerName 'CP-B3L40104-01.ntdev.corp.microsoft.com' -Credential $Credential -ScriptBlock $StopOnPremVMScriptBlock -ArgumentList $VMName
Start-Sleep -s 30

if($ifDoFailbackafterUPFO)
{
    Write-Host $("Triggering Planned Failback after UPFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrPlannedFailoverJob -ReplicationProtectedItem $VM -Direction RecoveryToPrimary
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************Failback finished for VM after upfo****************") -ForegroundColor Green
}

# Commit after Planned Failback with UPFO
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Write-Host $("****************VM fetched after Planned Failback with UPFO****************") -ForegroundColor Green

if($ifDoFailbackCommitwithUPFO)
{
    Write-Host $("Triggering Commit after UPFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrCommitFailoverJob -ReplicationProtectedItem $VM
    #-Direction RecoveryToPrimary
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Commit after Planned Failback finished for VM after UPFO***********") -ForegroundColor Green
}

# Reverse Replication after Planned Failback
$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM
Write-Host $("****************VM fetched after Commit****************") -ForegroundColor Green

if($ifDoFailbackRRafterUPFO)
{
    Write-Host $("Triggering Reverse Replication after upfo") -ForegroundColor Green
    $currentJob = Update-AzureRmRecoveryServicesAsrProtectionDirection -ReplicationProtectedItem $VM -Direction PrimaryToRecovery
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Reverse Replication finished for VM after upfo***********") -ForegroundColor Green
}

$VM = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer | where { $_.FriendlyName -eq $VMName }
Write-Host $("VM:") -ForegroundColor Green
$VM

#Stop-SCVirtualMachine -VM $VMName -Force

$VMList = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer
if($ifCreateRP)
{
    Write-Host $("Triggered Create RP") -ForegroundColor Green

    $VM = $VMList | where { $_.FriendlyName -eq $VMNameList[0] }

    $currentJob = New-AzureRmRecoveryServicesAsrRecoveryPlan -Name $RPName -PrimaryFabric $PrimaryFabric -RecoveryFabric $RecoveryFabric -ReplicationProtectedItem $VM
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

if($ifDoRPTFO)
{
    #$RecoveryServer = Get-AzureRmRecoveryServicesAsrServer -FriendlyName $RecoveryServerName
    #$RecoveryNetwork = Get-AzureRmRecoveryServicesAsrNetwork -Server $RecoveryServer | where { $_.FriendlyName -eq $RecoveryNetworkFriendlyName}

    Write-Host $("Triggered TFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrTestFailoverJob -RecoveryPlan $RP -Direction PrimaryToRecovery -VMNetwork $testRecoveryNetwork
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************TFO Started for VM****************") -ForegroundColor Green

    # Complete TFO
    Write-Host $("Started TFO Completion") -ForegroundColor Green
    $currentJob = Resume-AzureRmRecoveryServicesAsrJob -Name $currentJob.Name
    $currentJob
    Start-Sleep -s 120
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

for($i = 0; $i -lt $VMNameList.Count ; $i++)
{
    Invoke-Command -ComputerName 'CP-B3L40104-01.ntdev.corp.microsoft.com' -Credential $Credential -ScriptBlock $StopOnPremVMScriptBlock -ArgumentList $VMNameList[$i]
    Start-Sleep -s 30
}

if($ifDoRPPFORR)
{
    Write-Host $("Triggering Reverse Replication") -ForegroundColor Green
    $currentJob = Update-AzureRmRecoveryServicesAsrProtectionDirection -RecoveryPlan $RP -Direction RecoveryToPrimary 
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("************Reverse Replication finished for VM***********") -ForegroundColor Green
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
Start-Sleep -s 80
# Unplanned Failover
$RP = Get-AzureRmRecoveryServicesAsrRecoveryPlan -Name $RPName 
Write-Host $("RP:") -ForegroundColor Green
$RP

# Unplanned Failover
if($ifDoRPUFO)
{
    Write-Host $("Triggering UFO") -ForegroundColor Green
    $currentJob = Start-AzureRmRecoveryServicesAsrUnplannedFailoverJob -RecoveryPlan $RP -Direction PrimaryToRecovery
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
    Write-Host $("****************UFO finished for VM****************") -ForegroundColor Green
}

$RP = Get-AzureRmRecoveryServicesAsrRecoveryPlan -Name $RPName 
Write-Host $("RP:") -ForegroundColor Green
$RP

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


# Remove Networkmapping
Write-Host $("Started Remove Network Mapping") -ForegroundColor Green
$networkmapping = Get-AzureRmRecoveryServicesAsrNetworkMapping -Name $($PrimaryNetworkFriendlyName + $RecoveryNetworkFriendlyName + "map") -Network $PrimaryNetwork 
$networkmapping
$currentJob = Remove-AzureRmRecoveryServicesAsrNetworkMapping -NetworkMapping $networkmapping
$currentJob
WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
Write-Host $("****************Network Unmapping done****************") -ForegroundColor Green

# Disable Protection
<#
Write-Host $("Started Disable Protection") -ForegroundColor Green
$currentJob = Set-AzureRmRecoveryServicesAsrProtectionEntity -ProtectionEntity $VM -Protection Disable -Force
$currentJob
WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
Write-Host $("****************Disabled Protection for VM****************") -ForegroundColor Green
#>
$VMList = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryContainer
for($i = 0; $i -lt $VMNameList.Count ; $i++)
{
    $VM = $VMList | where { $_.FriendlyName -eq $VMNameList[$i] }
    Write-Host $("Started Disable Protection") -ForegroundColor Green
    $currentJob = Remove-AzureRmRecoveryServicesAsrReplicationProtectedItem -ReplicationProtectedItem $VM
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
$currentJob = Remove-AzureRmRecoveryServicesAsrServicesProvider -ServicesProvider $server[0]
$currentJob
WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
Write-Host $("****************Unregistered server 1:****************") -ForegroundColor Green
 $currentJob = Remove-AzureRmRecoveryServicesAsrServicesProvider -ServicesProvider $server[1]
$currentJob
WaitForJobCompletion -JobId $currentJob.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
Write-Host $("****************Unregistered server 2:****************") -ForegroundColor Green


