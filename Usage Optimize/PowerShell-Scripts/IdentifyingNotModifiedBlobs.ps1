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

#region Parameters
$daysBeforeCoolTier = 30
$daysBeforeArchiveTier = 365
$blobCountCoolTier = 0
$blobSizeCoolTier = 0
$blobCountArchiveTier = 0
$blobSizeArchiveTier = 0


$storageAccountName = "<StorageAccountName>"
$sasToken = "<SASToken>"
$maxReturn = 1000
$token = $null
#endregion Parameters

#region Intro
function intro()
{
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "WACO Waste Reduction - Identify Files that have not been modified" -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Green
}
#endregion Intro


#region Requirements
function requirements()
{
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "Checking if Azure Storage module is installed" -ForegroundColor White 

    if (Get-InstalledModule -Name Az.Storage -RequiredVersion "4.2.0" -ErrorAction ignore) 
    {
        Write-Host "======================================================================" -ForegroundColor Green
        Write-Host "Azure Storage Module 4.2.0 exists -- Perfect" -ForegroundColor White 
        Write-Host "======================================================================" -ForegroundColor Green
        Write-Host "Nothing to install. But loading in memory" -ForegroundColor White 
        Import-Module -Name Az.Storage -RequiredVersion "4.2.0" -Force
        Write-Host "======================================================================" -ForegroundColor Green
    }
    elseif (Get-InstalledModule -Name Az.Storage -RequiredVersion "4.2.0" -ErrorAction ignore) 
    {
        Write-Host "======================================================================" -ForegroundColor Green
        Write-Host "Azure Storage Module 4.2.0 exists -- Removing" -ForegroundColor White 
        Write-Host "======================================================================" -ForegroundColor Green
        Remove-Module -Name Az.Storage -Force -ErrorAction ignore
        Install-Module -Name Az.Storage -RequiredVersion "4.2.0" -Force
        Import-Module -Name Az.Storage -RequiredVersion "4.2.0" -Force
    }
    else 
    {
        Write-Host "======================================================================" -ForegroundColor Green
        Write-Host "Module 4.2.0 does not exist -- Installing it." -ForegroundColor White 
        Write-Host "======================================================================" -ForegroundColor Green
        Install-Module -Name Az.Storage -RequiredVersion "4.2.0" -Force
        Import-Module -Name Az.Storage -RequiredVersion "4.2.0" -Force
        Write-Host "Done." -ForegroundColor White 
        Write-Host "======================================================================" -ForegroundColor Green
    }
}
#endregion Requirements

#region Analysis
function analysis()
{
    $context = New-AzStorageContext -StorageAccountName $storageAccountName -SasToken $sasToken
    $containers = Get-AzStorageContainer -Context $context

    foreach ($container in $containers)
    {
        do 
        {
            $blobs = Get-AzStorageBlob -Container $container.Name -Context $context -maxCount $maxReturn -ContinuationToken $token
            if($blobs.Length -le 0) { Break;}
            foreach ($blob in $blobs)
            {
                if (((Get-Date).Date - $blob.LastModified.Date).TotalDays -ge $daysBeforeCoolTier)
                {
                    $blobCountCoolTier++
                    $blobSizeCoolTier += $blob.Length
                    if (((Get-Date).Date - $blob.LastModified.Date).TotalDays -ge $daysBeforeArchiveTier)
                    {
                        $blobCountArchiveTier++
                        $blobSizeArchiveTier += $blob.Length
                    }
                }
            }
            $token = $blobs[$blobs.Count -1].ContinuationToken;
        }
        While ($null -ne $token)
    }
    
    $sizeCoolTierGB = $blobSizeCoolTier/1GB
    $sizeArchiveTierGB = $blobSizeArchiveTier/1GB

    Write-Host
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "Analysis of the Storage Account " $storageAccountName -ForegroundColor Green
    Write-Host
    Write-Host "Cool Tier Analysis" -ForegroundColor Green
    Write-Host "------------------" -ForegroundColor Green
    Write-Host
    Write-Host "Number of blobs not modified in the last " $daysBeforeCoolTier " days: " $blobCountCoolTier -ForegroundColor White
    Write-Host "Size of blobs not modified (in GB):" $sizeCoolTierGB -ForegroundColor White

    Write-Host
    Write-Host "Archive Tier Analysis" -ForegroundColor Green
    Write-Host "---------------------" -ForegroundColor Green
    Write-Host
    Write-Host "Number of blobs not modified in the last " $daysBeforeArchiveTier " days: " $blobCountArchiveTier -ForegroundColor White
    Write-Host "Size of blobs not modified (in GB):" $sizeArchiveTierGB -ForegroundColor White
}
#endregion Analysis

Try
{
    $sessionSpace = get-clouddrive
    if ($sessionSpace) 
    {
        Write-Host "====================================" -ForegroundColor Green
        Write-Host "    Running in Cloud Shell mode" -ForegroundColor Green
        Write-Host "====================================" -ForegroundColor Green
        intro
        analysis
    }
}
Catch 
{
    intro
    requirements
    analysis
}