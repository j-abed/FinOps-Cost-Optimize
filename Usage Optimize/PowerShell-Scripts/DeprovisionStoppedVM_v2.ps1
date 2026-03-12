<#
   
.NOTES
    THIS CODE-SAMPLE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED 
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR 
    FITNESS FOR A PARTICULAR PURPOSE.

    This sample is not supported under any Microsoft standard support program or service. 
    The script is provided AS IS without warranty of any kind. Microsoft further disclaims all
    implied warranties including, without limitation, any implied warranties of merchantability
    or of fitness for a particular purpose. The entire risk arising out of the use or performance
    of the sample and documentation remains with you. In no event shall Microsoft, its authors,
    or anyone else involved in the creation, production, or delivery of the script be liable for 
    any damages whatsoever (including, without limitation, damages for loss of business profits, 
    business interruption, loss of business information, or other pecuniary loss) arising out of 
    the use of or inability to use the sample or documentation, even if Microsoft has been advised 
    of the possibility of such damages, rising out of the use of or inability to use the sample script, 
    even if Microsoft has been advised of the possibility of such damages.

#>

<# Instructions to use this script

1. Set the file path for the CSV ($CsvFilePath)
2. Run the script

#>

#region Parameters
$CsvFilePath = "C:\Temp\StoppedVMs.csv"
$tenantID = "<TenantID>"
#endregion Parameters

function intro()
{
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "WACO Waste Reduction - Deprovisioning Stopped VMs" -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Green
}

function requirements()
{
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "Checking if Azure Compute module is installed" -ForegroundColor White 

    if (Get-InstalledModule -Name Az.Compute -RequiredVersion "4.30.0" -ErrorAction ignore) 
    {
        Write-Host "======================================================================" -ForegroundColor Green
        Write-Host "Azure Compute Module 4.30.0 exists -- Perfect" -ForegroundColor White 
        Write-Host "======================================================================" -ForegroundColor Green
        Write-Host "Nothing to install. But loading in memory" -ForegroundColor White 
        Import-Module -Name Az.Compute -RequiredVersion "4.30.0" -Force
        Write-Host "======================================================================" -ForegroundColor Green
    }
    elseif (Get-InstalledModule -Name Az.Compute -RequiredVersion "4.30.0" -ErrorAction ignore) 
    {
        Write-Host "======================================================================" -ForegroundColor Green
        Write-Host "Azure Compute Module 4.30.0 exists -- Removing" -ForegroundColor White 
        Write-Host "======================================================================" -ForegroundColor Green
        Remove-Module -Name Az.Compute -Force -ErrorAction ignore
        Install-Module -Name Az.Compute -RequiredVersion "4.30.0" -Force
        Import-Module -Name Az.Compute -RequiredVersion "4.30.0" -Force
    }
    else 
    {
        Write-Host "======================================================================" -ForegroundColor Green
        Write-Host "Azure Compute Module 4.30.0 does not exist -- Installing it." -ForegroundColor White 
        Write-Host "======================================================================" -ForegroundColor Green
        Install-Module -Name Az.Compute -RequiredVersion "4.30.0" -Force
        Import-Module -Name Az.Compute -RequiredVersion "4.30.0" -Force
        Write-Host "Done." -ForegroundColor White 
        Write-Host "======================================================================" -ForegroundColor Green
    }

    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "Checking if Azure Accounts module is installed" -ForegroundColor White 

    if (Get-InstalledModule -Name Az.Accounts -RequiredVersion "2.9.1" -ErrorAction ignore) 
    {
        Write-Host "======================================================================" -ForegroundColor Green
        Write-Host "Azure Accounts Module 2.9.1 exists -- Perfect" -ForegroundColor White 
        Write-Host "======================================================================" -ForegroundColor Green
        Write-Host "Nothing to install. But loading in memory" -ForegroundColor White 
        Import-Module -Name Az.Accounts -RequiredVersion "2.9.1" -Force
        Write-Host "======================================================================" -ForegroundColor Green
    }
    elseif (Get-InstalledModule -Name Az.Accounts -RequiredVersion "2.9.1" -ErrorAction ignore) 
    {
        Write-Host "======================================================================" -ForegroundColor Green
        Write-Host "Azure Accounts Module 2.9.1 exists -- Removing" -ForegroundColor White 
        Write-Host "======================================================================" -ForegroundColor Green
        Remove-Module -Name Az.Accounts -Force -ErrorAction ignore
        Install-Module -Name Az.Accounts -RequiredVersion "2.9.1" -Force
        Import-Module -Name Az.Accounts -RequiredVersion "2.9.1" -Force
    }
    else 
    {
        Write-Host "======================================================================" -ForegroundColor Green
        Write-Host "Azure Accounts Module 2.9.1 does not exist -- Installing it." -ForegroundColor White 
        Write-Host "======================================================================" -ForegroundColor Green
        Install-Module -Name Az.Accounts -RequiredVersion "2.9.1" -Force
        Import-Module -Name Az.Accounts -RequiredVersion "2.9.1" -Force
        Write-Host "Done." -ForegroundColor White 
        Write-Host "======================================================================" -ForegroundColor Green
    }
}

function connectAz()
{
    Connect-AzAccount -Tenant $tenantID
}


function removeCS()
{
    $CSV = Import-CSV "$CsvFilePath"
    $CSV | ForEach-Object{
        $subscription = Get-AzSubscription -SubscriptionId $_.subscriptionId
        Set-AzContext -Subscription $subscription.Name

        $ResourceGroupName = $_.resourceGroup.Substring($_.resourceGroup.LastIndexOf('/') + 1)
        $VMName = $_.id.Substring($_.id.LastIndexof('/')+1)
        
        Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
    }
}

function remove()
{
    $CSV = Import-CSV "$CsvFilePath" | Out-GridView -Title "Select VMs to deallocate" -PassThru
    $CSV | ForEach-Object{
        $subscription = Get-AzSubscription -SubscriptionId $_.subscriptionId
        Set-AzContext -Subscription $subscription.Name

        $ResourceGroupName = $_.resourceGroup.Substring($_.resourceGroup.LastIndexOf('/') + 1)
        $VMName = $_.id.Substring($_.id.LastIndexof('/')+1)

        Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force
    }
}

Try
{
    $sessionSpace = get-clouddrive
    if ($sessionSpace) 
    {
        Write-Host "====================================" -ForegroundColor Green
        Write-Host "    Running in Cloud Shell mode" -ForegroundColor Green
        Write-Host "====================================" -ForegroundColor Green
        removeCS
    }
}
Catch 
{
    requirements
    connectAz
    remove
}