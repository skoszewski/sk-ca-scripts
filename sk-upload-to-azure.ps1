param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [string]$ResourceGroup,
    [string]$StorageAccount,
    [string]$Container
)

if(!(Test-Path -Path $Path)) {
    throw "$Path does not exist."
}

$file = Get-ChildItem -Path $Path

# Check, if the account has been selected using the script parameters
if ($ResourceGroup -and $StorageAccount -and $Container) {
    # Getting token using Azure PowerShell Module
    $context = (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -AccountName $StorageAccount).Context
    $SasToken = New-AzStorageAccountSASToken -Context $context -Service Blob -ResourceType Container,Object -Permission "racwdlup"

    # NOTE: SAS tokens generated using the powershell command-let already include the question mark needed to separate
    # location from parameters in the Uri.
    $Uri = $context.BlobEndPoint + "$Container/$($file.BaseName + $file.Extension)$SasToken"

} else {
    # No, look for shell environment variables
    if (!($env:SAS_TOKEN -and $env:STORAGE_ACCOUNT -and $env:CONTAINER)) {
        # Account information not found, bail out.
        throw "Azure BLOB container information must be defined in environment variables: SAS_TOKEN, STORAGE_ACCOUNT and CONTAINER."
    }

    $Uri = "https://$env:STORAGE_ACCOUNT.blob.core.windows.net/$env:CONTAINER/$($file.BaseName + $file.Extension)?$env:SAS_TOKEN"
}

# Upload the file
Invoke-WebRequest -Uri $Uri -Headers @{ "x-ms-blob-type" = "BlockBlob" } -Method Put -Body (Get-Content -Path $Path -Raw)
