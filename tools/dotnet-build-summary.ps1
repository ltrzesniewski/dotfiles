#
# Pipeline which processes the output of a dotnet build command and outputs only the summary,
# including hyperlinks for errors and warnings that open in VS Code.
#
# Helps with large refactorings.
#

param(
    [Parameter(ValueFromPipeline = $true)]
    [string]$InputLine
)

begin {
    $script:buildResultSeen = $false
    $script:previousProject = $null

    Write-Output "`e[0;3mProcessing...`e[0m"
}

process {
    # Check if this line contains the build result message
    if (-not $script:buildResultSeen -and $InputLine -match '^Build (?<result>succeeded|FAILED)\.') {
        $script:buildResultSeen = $true

        # Format with bold and color based on result
        $result = $matches['result']
        $coloredLine = if ($result -eq 'succeeded') {
            "`e[0;1;92m$InputLine`e[0m" # Bold bright green
        } elseif ($result -eq 'FAILED') {
            "`e[0;1;91m$InputLine`e[0m" # Bold bright red
        } else {
            $InputLine
        }

        Write-Output "`e[1A`e[2K" # Clear previous line
        Write-Output $coloredLine
        return
    }

    # Skip all lines until we see the build result message
    if (-not $script:buildResultSeen) {
        return
    }

    # Pattern to match file paths in dotnet build errors
    # Matches: path\to\file.cs(line,column): error/warning CS1234: Message
    if ($InputLine -match @'
(?x) ^
(?<fullPath>
    (?<filePath> .+? [\\/] )
    (?<fileName> [^\\/:]+? )
)
(?<location> \( (?<line>[0-9]+),(?<column>[0-9]+) \) )
: [ ]
(?<type>error|warning)
[ ]
(?<code> [A-Z0-9]+ )
: [ ]
(?<message> .+? )
(?:
    [ ] \[ (?<project> .+? ) \]
)?
$
'@) {
        $fullPath = $matches['fullPath']
        $filePath = $matches['filePath']
        $fileName = $matches['fileName']
        $location = $matches['location']
        $line = $matches['line']
        $column = $matches['column']
        $type = $matches['type']
        $code = $matches['code']
        $message = $matches['message']
        $project = $matches['project']

        $vscodeUri = "vscode://file/$($fullPath.Replace('\', '/')):${line}:${column}"
        $hyperlink = "`e]8;;${vscodeUri}`e\${fileName}`e]8;;`e\"

        $typeColor = if ($type -eq 'error') { "91" } else { "93" } # Red/Yellow

        if ($project -ne $script:previousProject) {
            if ($script:previousProject) {
                Write-Output "" # Add spacing between projects
            }

            Write-Output "`e[0;1;97mProject:`e[0m $($project ? $project : '(none)')`e[0m"
            $script:previousProject = $project
        }

        Write-Output "`e[0m${filePath}`e[0;1;97m${hyperlink}`e[0;2m${location}: `e[0;${typeColor}m${type} ${code}`e[0m: ${message}`e[0m"
    }
    else {
        if ($InputLine -match '^[ ]{4}[0-9]+ Warning\(s\)$') {
            Write-Output ""
        }

        Write-Output $InputLine
        $script:previousProject = $null
    }
}

end {
    if (-not $script:buildResultSeen) {
        Write-Output "`e[1A`e[2K" # Clear "Processing..."
        Write-Output "`e[0;93mNo build result found in output. Please ensure this script is used with the output of a dotnet build command.`e[0m"
        exit 1
    }
}
