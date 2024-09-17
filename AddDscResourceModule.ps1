# This will copy the module to the correct local location to use for creating configuration mof files

$folderName = 'RenameBuiltinAccount'

$baseFolder = 'C:\Users\ScottBarrett\Code\dsc'

Join-Path -Path $baseFolder -ChildPath $folderName

Copy-Item -Path $folderName -Destination "$env:ProgramFiles\WindowsPowerShell\Modules" -Force -Recurse

