# Why this tool exists
According to Front Door Standard/Premium documentation on [Apex Domains](https://learn.microsoft.com/en-us/azure/frontdoor/apex-domain#azure-front-door-managed-tls-certificate-rotation), when a Managed Certificate is pending renewal, it is necessary to manually regenerate a TXT record token. The managed certificate lifetime currently is 180 days; this is not stated anywhere in public documentation likely due to it being subject to change. When a certificate is less than 45 days from expiry, revalidation can be performed. With CNames, revalidation is an automated process. With Apex Domains, it is manual.

Say you are domain-squatting several hundred apex domains (ones w/ typos, sister sites that now should be accessed via the main site) and you've configured these sites to redirect to the main intended site. Each of these would have a Managed Certificate just for that Apex Domain. Due to the short certificate lifetime and the manual nature of the revalidation, revalidating these manually would be a laborious task.

**This tool seeks to automate a portion of that by generating new TXT record tokens for Apex Domains with Managed Certificates expiring in less than 45 days and outputting them so they can be entered into your DNS provider of choice.**
# How to use
This script uses the AzCLI module and PowerShell.

Within a PowerShell session and logged into your Azure account, run the script with .\AFDApexDomainScript.ps1.

Alternatively, you can upload this to a CloudShell session within Portal and run it there. The script will prompt for your ResourceGroup and FrontDoor profile name.

# Limitations
This script does not automatically update your DNS TXT records with the new values -- it merely lists the new values and the hostname the value is associated to. There is a [7-day window](https://learn.microsoft.com/en-us/azure/frontdoor/domain#:~:text=The%20TXT%20record%20wasn%27t%20added%20to%20your%20DNS%20provider%20within%20seven%20days%2C%20or%20an%20invalid%20DNS%20TXT%20record%20was%20added.) to update the TXT record value. Even assuming one is using Azure DNS, each Domain zone is a separate Resource, so it wouldn't be possible to automate this.
