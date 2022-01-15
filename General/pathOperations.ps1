<#
.SYNOPSIS
Used to get the absolute path of a provided location.
Won't performs any action if the path is already 'absolute'.

.DESCRIPTION
Long description

.PARAMETER targetPath
Target path (file, folder, etc...)

.EXAMPLE
Get-AbsolutePath('.\test.log')

.EXAMPLE
Get-AbsolutePath('C:\test.log')

.NOTES
General notes
#>
function Get-AbsolutePath() {
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string] $targetPath
    )

    #Return the path without performing any operation if it is already an absolute 
    if ([System.IO.Path]::IsPathRooted($targetPath)) {
        return $targetPath;
    }

    return [System.IO.Path]::Combine((Get-Location).ProviderPath, $targetPath);
}
