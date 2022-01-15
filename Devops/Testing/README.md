# Devops Testing:
Folder contains dedicated functions used to assist developers with the testing of created artifacts before deploying / delivering them to the end user.

## msiValidaiton.ps1:
Used to validate the properties of a generated .msi file 
Note: the funciton ```Confirm-MsiProperties ``` uses the function ```Get-AbsolutePath ``` which can be found in the [pathOperations.ps1](https://github.com/Ido-Saroka/Powershell/blob/main/General/pathOperations.ps1) file (under the "General" directory in the Powershell main repo)
