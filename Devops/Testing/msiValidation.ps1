<#
.SYNOPSIS
Function is used to get a specific property value from a provided msiDB (Com object)

.DESCRIPTION
Allows querying a given msiDB using SQL in order to retrieve the value of a specific property.

.PARAMETER msiDB
The com object representation of a given msi 

.PARAMETER propertyToGet
THe name of the property to retrieve from the msi

.EXAMPLE
Get-MsiProperty $msiDB "UpgradeCode"

.NOTES
#Based on this post:https://stackoverflow.com/a/8743878/13829249
#Information regarding invoke member - https://docs.microsoft.com/en-us/dotnet/api/system.type.invokemember?redirectedfrom=MSDN&view=net-5.0#overloads
#>
function Get-MsiProperty() {
    [CmdletBinding()]
    param (
        [ValidateNotNull()]
        [parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True)]
        [System.__ComObject] $msiDB,

        [ValidateNotNullOrEmpty()]
        [parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string] $propertyToGet
    )
    try {
        #Prepare the query to retrieve the msi property
        [string]$propQuery = "SELECT Value FROM Property WHERE Property = '$propertyToGet'"
        [System.__ComObject]$propView = $msiDB.GetType().InvokeMember(
            "OpenView", "InvokeMethod", $Null, $msiDB, ($propQuery)
        )
        #Open view to the msi db in order to retrieve the property
        $propView.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $propView, $Null)

        [System.__ComObject]$record = $propView.GetType().InvokeMember(
            "Fetch", "InvokeMethod", $Null, $propView, $Null
        )

        if ($null -eq $record) {
            throw "The property $propertyToGet was not found inside the msi."
        }
        
        #Get target property value
        [string]$propertyValue = $record.GetType().InvokeMember(
            "StringData", "GetProperty", $Null, $record, 1
        )

        #Close the object before returning the result else later access attempts may fail
        $propView.GetType().InvokeMember("Close", "InvokeMethod", $Null, $propView, $Null)
        return $propertyValue;
    }
    catch [system.exception] {  
        #Close the object after accessing it else later access to it may fail
        $propView.GetType().InvokeMember("Close", "InvokeMethod", $Null, $propView, $Null)
        #Print the current exception and throw a custom one
        $_
        throw "Failed to get $propertyToGet value the error was: {0}." -f $_
    }
}

<#
.SYNOPSIS
Used to validate that the values of a generated MSI match those specified in the build process

.DESCRIPTION
Long description

.PARAMETER msiToValidate
The path to the msi file we wish to validate

.PARAMETER msiPropertiesToValidate
An array of ordered hash tables containing the properties to test and their expected values

.EXAMPLE
An example

.NOTES
Based on the following resources:
* https://stackoverflow.com/a/8743878/13829249
* https://docs.microsoft.com/en-us/dotnet/api/system.type.invokemember?redirectedfrom=MSDN&view=net-5.0#overloads
#>
function Confirm-MsiProperties() {
    [CmdletBinding()]
    param (
        [ValidateScript({ Confirm-FileIsValid -fileToValidate $_ -fileExtension "msi" })]
        [parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string] $msiToValidate,

        [parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True)]
        [System.Array] $msiPropertiesToValidate
    )
    try {
        #Get the absolute msi path
        [string]$absPathToMsi = Get-AbsolutePath($msiToValidate)

        #Create the relevant com objects that will be used to retrieve the properties from the msi file
        [System.__ComObject]$windowsInstaller = New-Object -com WindowsInstaller.Installer

        [System.__ComObject]$msiDB = $windowsInstaller.GetType().InvokeMember(
            "OpenDatabase", "InvokeMethod", $Null, 
            $windowsInstaller, @($absPathToMsi, 0)
        )

        #Get key and property name
        [string] $keyName = $($msiPropertiesToValidate[0].Keys)[0]
        [string] $PropValue = $($msiPropertiesToValidate[0].Keys)[1]

        #Iterate over each of the properties and validate that value inside the msi matches the expected value
        for ($i = 0; $i -lt $msiPropertiesToValidate.Count; $i++) {

            #Trim leading and trailing spaces (may cause a failure to retrieve the property)
            [string]$propertyToGet = ($msiPropertiesToValidate[$i].$keyName).trim()

            #Get the property from the msi
            [string] $propertyValueFromMsi = (Get-MsiProperty $msiDB $propertyToGet)[-1]
            if ($propertyValueFromMsi -ne $msiPropertiesToValidate[$i].$PropValue) {

                #Build the error message
                [string]$propErrorMessage = (
                    "Error in generated property $($msiPropertiesToValidate[$i].$keyName)", 
                    "| Expected Value: $($msiPropertiesToValidate[$i].$PropValue)",
                    "| Actual Value: $propertyValueFromMsi"
                ) -join ' '

                throw [System.Exception] $propErrorMessage
            }
        }
    }
    catch {
        #Throw the exception to interrupt the build process
        throw $_
    }
    finally {
        #Release com objects to prevent the error: "The process cannot access the file because it is being used by another process."
        $windowsInstaller = $null;
        $msiDB = $null;
    }
}

