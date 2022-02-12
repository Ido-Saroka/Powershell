#Set path to script location
Set-Location $PSScriptRoot

<#
.SYNOPSIS
Used to load the websites address from the csv file

.PARAMETER pathToCsvFile
The csv file that stores the websites

.PARAMETER csvHeader
The header that stores the websites we want to perform a custom search in

.EXAMPLE
An example
#>
Function Get-CsvSiteInfo {
    param(
        # Path to site csv file
        [Parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True
        )]
        [ValidateScript({ Test-Path $_ })]
        [string] $pathToCsvFile,

        [Parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True
        )]
        [ValidateNotNullOrEmpty()]
        [string] $csvHeader
    )
    if ([System.IO.Path]::GetExtension($pathToCsvFile) -ne '.csv') {
        throw "Can't perform custom search, file isn't a csv"
    }
    #TODO:: add option to load all websites from the csv
    return Get-Content $pathToCsvFile | Select-Object -skip 2 | ConvertFrom-Csv -Header $csvHeader
}

<#
.SYNOPSIS
Convert a given url to a format that will allow custom search 

.PARAMETER urlToStrip
Url to be converted

.EXAMPLE
#Output will be: askubuntu.com
Convert-URL "https://askubuntu.com/" 
#>
Function Convert-URL {  
    param(
        [parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True
        )]
        [ValidateNotNullOrEmpty()]
        [string] $urlToStrip
    )
    #Regex to match protocol at the start of the url
    $schemaRegex = '^(http|https)://'
    #Remove schema and '/' at the end of the url if exists
    return ($urlToStrip -replace $schemaRegex).TrimEnd('/').ToString();
}


#https://stackoverflow.com/questions/32703483/get-google-search-results-via-powershell
#Read sites value from an excel document
#Create a search string and run a search

<#
.SYNOPSIS
Used in order to simplify the custom search ability that is available inside certain search engines

.PARAMETER searchQuery
The search term that will be searched

.EXAMPLE
 Invoke-CustomWebSearch  "ngix server 14"

.NOTES
Additional information about the custom search ability:
* Overview of Google search operators - https://developers.google.com/search/docs/advanced/debug/search-operators/overview
#>
Function Invoke-CustomWebSearch {
    param(
        [parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True
        )]
        [ValidateNotNullOrEmpty()]
        [string] $searchQuery
    )

    #Get list of site from csv file
    $listOfSiteFromCSV = Get-CsvSiteInfo '.\SitesToSearchIn.csv' 'Search Sites:'
    #Use string builder to reduce performance usage
    $siteSearchString = [System.Text.StringBuilder]::new()

    #Build the sites search string in the following format: 'site:<site_urL_without_protocal>'
    for ($i = 0; $i -lt $listOfSiteFromCSV.Count; $i++) {
        [void]$siteSearchString.Append('site%3A')
        $stripedSite = Convert-URL $listOfSiteFromCSV[$i].psobject.properties.value.TrimStart("'").TrimEnd("'")
        [void]$siteSearchString.Append($stripedSite);
        [void]$siteSearchString.Append(' OR ');
    }

    #Remove last ' OR' from string
    $siteSearchString = $siteSearchString -replace "(.*) OR(.*)", '$1$2';
    #TODO:: add support for additional search engines that allow for custom search  
    $searchEngineToUse = "Google"
    $searchEnginePrefix = switch ($searchEngineToUse) {
        Default {
            "https://www.google.com/search?q=$searchQuery+"
        }
    }
    Start-Process "$searchEnginePrefix$siteSearchString"
}

<#
.SYNOPSIS
Will write text which in custom format to the screen
#>
Function CustomWriteHost {
    param(
        [parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True
        )]
        [ValidateNotNullOrEmpty()]
        [string] $textToPrint
    ) 
    Write-Host "**** $($textToPrint)" -ForegroundColor Black -BackgroundColor White
}

Set-Alias cws Invoke-CustomWebSearch

CustomWriteHost "In order to perform custom web search use the following command:"
CustomWriteHost "cws <Search_Term> for example: cws ngix server 14" 
