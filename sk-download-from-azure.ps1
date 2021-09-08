param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [string]$ResourceGroup,
    [string]$StorageAccount,
    [string]$Container
)

if(Test-Path -Path $Path -PathType Leaf) {
    throw "There is a file at `"$Path`", do not specify an existing file."
}

$FileName = Split-Path $Path -Leaf
$DirectoryName = Split-Path $Path -Parent

if(!(Test-Path -Path $DirectoryName -PathType Container)) {
    throw "The destination directory does not exist."
}

# Check, if the account has been selected using the script parameters
if ($ResourceGroup -and $StorageAccount -and $Container) {

    # Getting token using Azure PowerShell Module
    $context = (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -AccountName $StorageAccount).Context
    
    # Create an Uri with a SAS token. Use CREATE only permission to prevent overwriting existing blobs.
    $Uri = New-AzStorageBlobSASToken -Context $context -Container $Container -Blob $FileName -Permission "r" -FullUri

} else {
    
    # No, look for shell environment variables
    if (!($env:SAS_TOKEN -and $env:STORAGE_ACCOUNT -and $env:CONTAINER)) {
        # Account information not found, bail out.
        throw "Azure BLOB container information must be defined in environment variables: SAS_TOKEN, STORAGE_ACCOUNT and CONTAINER."
    }

    $Uri = "https://$env:STORAGE_ACCOUNT.blob.core.windows.net/$env:CONTAINER/$FileName?$env:SAS_TOKEN"
}

# Download the file and discard the output. Exceptions will provide error information.
Invoke-WebRequest -Uri $Uri -OutFile $Path | Out-Null
