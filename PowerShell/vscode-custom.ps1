
# https://github.com/microsoft/vscode/issues/95670#issuecomment-1186586327

Add-Type -AssemblyName System.Web

$path = $args[0] -replace "^vscode-custom://file/", ""
$file = [System.Web.HTTPUtility]::UrlDecode($path)
code --goto "$file"
