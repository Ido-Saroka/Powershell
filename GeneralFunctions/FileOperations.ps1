<#
.SYNOPSIS
    Validates a file exists , function can also be used to test its extension 
.EXAMPLE
    PS C:\> Confirm-FileIsValid -fileToValidate "iconFile.ico" -fileExtension "ico"
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
function Confirm-FileIsValid {
    [CmdletBinding()]
    param (
        #The path to the file you wish to validate
        [parameter(
            Mandatory = $TRUE,
            ValueFromPipeline = $True)]
        [string]$fileToValidate,

        #File extension without the "dot" i.e.: "exe","ico","png" etc..
        [parameter(
            ValueFromPipeline = $True)]
        [string]$fileExtension = $null
    )

    if (($null -eq $fileToValidate) -or (-Not (Test-Path $fileToValidate))) {
        throw "File doesn't exist"
    }
    #Validate file extension matches the specified value
    if (($null -ne $fileExtension ) -and ([IO.Path]::GetExtension($fileToValidate) -ne ".$fileExtension")) {
        throw "File is a $([IO.Path]::GetExtension($fileToValidate)) and not a $fileExtension"
    }
    return $true
}