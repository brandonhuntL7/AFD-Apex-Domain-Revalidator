#Script for Apex Domain Managed Cert revalidation
#If less than 45 days, eligible for revalidation. Then regenerate TXT record token to update DNS TXT record value.

#This script uses AzCLI module and PowerShell. Confirmed can be run in Azure CloudShell (accessed via Portal) under Powershell session.

#Define variables
$resourceGroupName = Read-Host "What is the ResourceGroup?"
$frontDoorName = Read-Host "What is the FrontDoor profile name?"
$date_45_days=(Get-Date).ToUniversalTime().AddDays(45).ToString("yyyy-MM-ddTHH:mm:ssZ")


##Gets list of Expiring Managed Certs, then their Cert CN/Subjects, then filters for only Apex Domains
$ExpiringDomains = az afd secret list `
    --resource-group $resourceGroupName `
    --profile-name $frontDoorName `
    --query "[?parameters.expirationDate <= '$date_45_days' && parameters.type == 'ManagedCertificate']" `
    --output json 
#Error-handling here if this variable is empty (i.e. no Managed Certificates expiring in less than 45 days)
if ($ExpiringDomains -eq "[]" -or $ExpiringDomains.Count -eq 0) {
        Write-Host "No expiring Managed Certificates found. Exiting script." -ForegroundColor Red
        exit 1
    }
$Subjects = $ExpiringDomains | ConvertFrom-Json | ForEach-Object { $_.parameters.subject }
$ApexDomains = $Subjects | Where-Object { ($_ -split '\.').Count -eq 2 }
#Error-handling here if this is empty (i.e. no Apex Domains found)
if (-not $ApexDomains -or $ApexDomains.Count -eq 0) {
        Write-Host "No Apex Domains found. Exiting script." -ForegroundColor Red
        exit 1
    }
    
##Create filter on Apex Hostnames only. Get list of Custom Domain Names for TXT record regeneration.
$ApexFilter = ($ApexDomains | ForEach-Object { "contains(hostName, '$_')" }) -join " || "
$CustomDomains = az afd custom-domain list `
    --resource-group $resourceGroupName `
    --profile-name $frontDoorName `
    --query "[? $ApexFilter ].{Domains:hostName, Name:name}" `
    --output tsv
$CustomDomainNames = @(
    foreach ($line in $CustomDomains) {
        $parts = $line -split '\t'
        if ($parts.Count -ge 2) {
            $parts[1]
        }
    }
)
#Iteratively issue TXT revalidation tokens on each of the custom domains
foreach ($domain in $customDomainNames) {
    az afd custom-domain regenerate-validation-token `
        --resource-group $resourceGroupName `
        --profile-name $frontDoorName `
        --custom-domain-name $domain
}

#Output Domain and new TXT values
foreach ($domain in $customDomainNames) {
az afd custom-domain show `
    --resource-group $resourceGroupName `
    --profile-name $frontDoorName `
    --custom-domain-name $domain `
    --query "{Domain:hostName, TXTRecord:validationProperties.validationToken}" `
    --output tsv
}

##Confirm&List Revalidated Domains
Write-Host "Regenerated certificate validation tokens for the following expiring Front Door domain names:" -ForegroundColor Green
foreach ($domain in $customDomainNames)  {
    Write-Host $domain
}