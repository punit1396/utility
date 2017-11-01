# Use the script like this - .\CreateV2Vm.ps1 -uniqueSuffixStart 105 -vmCount 10 -vmPrefixName "vaguptaV2ea"

param(
	[Parameter(mandatory=$true)]
    [int] $uniqueSuffixStart = 3081,
	
	[Parameter(mandatory=$true)]
    [int] $vmCount = 4,
	
	[Parameter(mandatory=$false)]
	[string] $vmPrefixName = "avraiV2ea",

	[Parameter(mandatory=$false)]
	[int] $dataDisksToAttach = 0,

	[Parameter(mandatory=$false)]
	[string] $subscriptionId = '6808dbbc-98c7-431f-a1b1-9580902423b7',

	[Parameter(mandatory=$false)]
	[string] $rgName = "vaguptaea1",

	[Parameter(mandatory=$false)]
	[string] $location = "EastAsia",

	[Parameter(mandatory=$false)]
	[string] $vmSize = "Standard_DS1",

	[Parameter(mandatory=$false)]
	[int] $dataDiskSizeInGB = 1,

	[Parameter(mandatory=$false)]
	[string] $storageId = "https://vaguptav2ea1.blob.core.windows.net/vhds/",

	[Parameter(mandatory=$false)]
	[string] $priNetworkId = "/subscriptions/6808dbbc-98c7-431f-a1b1-9580902423b7/resourceGroups/vaguptaEa1/providers/Microsoft.Network/virtualNetworks/vaguptaV2Ea2"
)

$vmNameLength = $vmPrefixName.length + 1 + ([string]$uniqueSuffixStart).length;
if ($vmNameLength -gt 15)
{
	Write-Host $("VM name should not be greater than 15 chars. Your first VM name length is $vmNameLength.") -foregroundcolor red;
	exit;
}

Login-AzureRmAccount
$context = Get-AzureRmContext
Select-AzureRmSubscription -TenantId $context.Tenant.TenantId -SubscriptionId $subscriptionId

$secPwd = ConvertTo-SecureString "" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential("", $secPwd)
$subnetId = "$priNetworkId/subnets/default"

Write-Host $("Using subscription	: " + $subscriptionId + "`n");
Write-Host $("Using location		: " + $location + "`n");
Write-Host $("Using rgName	: " + $rgName + "`n");
Write-Host $("Using storage account	: " + $storageId + "`n");
Write-Host $("Using network		: " + $priNetworkId + "`n");
Write-Host $("Using subnetId		: " + $subnetId + "`n");
Write-Host $("Using vmSize		: " + $vmSize + "`n");

$createdCount = 0;
$failedCount = 0;
$totalTimeInSeconds = 0;

for($suffix = $uniqueSuffixStart; $suffix -lt $uniqueSuffixStart + $vmCount; $suffix++)
{
	$stopWatch = [Diagnostics.Stopwatch]::StartNew()
	
	try
	{	
		$vmName = "avraiV2ea-" + $suffix

		$diskNameOS = $($vmName+"-OS")
		$osDiskVhdUri = "$storageId$diskNameOS.vhd"

		$vm = New-AzureRmVMConfig -VMName $vmName  -VMSize $vmSize
		$vm = Set-AzureRmVMOperatingSystem `
			 -VM $vm `
			 -Windows `
			 -ComputerName $vmName `
			 -Credential $creds `
			 -ProvisionVMAgent -EnableAutoUpdate
		$vm = Set-AzureRmVMSourceImage `
			 -VM $vm `
			 -PublisherName MicrosoftWindowsServer `
			 -Offer WindowsServer `
			 -Skus 2012-Datacenter `
			 -Version latest
		$vm = Set-AzureRmVMOSDisk `
			 -VM $vm `
			 -Name $disknameOS `
			 -CreateOption FromImage `
			 -Caching ReadWrite `
			 -VhdUri $osDiskVhdUri     

        for($dataDiskNumber = 0; $dataDiskNumber -lt $dataDisksToAttach; $dataDiskNumber++)
        {
            $diskNameDD = $($vmName+"-dd" + $dataDiskNumber)
            $dataDiskVhdUri = "$storageId$diskNameDD.vhd"
		    $vm = add-azurermvmdatadisk -vm $vm `
		        -name $diskNameDD `
		        -vhduri $dataDiskVhdUri `
		        -caching readwrite `
		        -lun $dataDiskNumber `
		        -createoption empty `
                -DiskSizeInGB 1
        }
		 
		$nic = New-AzureRmNetworkInterface -Name "$vmName-nic" -ResourceGroupName $rgName -Location $location -SubnetId $subnetId -Force
		$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id         

		$currentJob = New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm
		
		if (($currentJob -eq $null) -or ($currentJob.IsSuccessStatusCode -eq $false) -or ($currentJob.StatusCode -ne "OK"))
		{
			throw "Check the above exception thrown by Azure.";
		}
		
		Write-Host $("Created VM:");
        $aureVM = Get-AzureRmVM -Name $vmName -ResourceGroupName $rgName
        $aureVM.Id
		$createdCount++;
		
	}
	catch
	{
		Write-Host "Couldn't create VM: $vmName. Error details - $_ `n" -foregroundcolor red
		$failedCount++;
	}
	finally
	{
		$stopWatch.Stop()
		$timeTaken = $stopWatch.Elapsed.TotalSeconds;
		$totalTimeInSeconds += $timeTaken;
		Write-Host $("Time taken: $timeTaken secs." + "`n");
	}
}

Write-Host $("Created count: " + $createdCount + "`n") -foregroundcolor green;
Write-Host $("Failed count: " + $failedCount + "`n") -foregroundcolor red;
Write-Host $("Total time taken: $totalTimeInSeconds secs." + "`n");
