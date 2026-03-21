#
# Pipeline which processes the output of a "dotnet build" command and outputs only the summary,
# including hyperlinks for errors and warnings that open in VS Code.
#
# Helps with large refactorings.
#

param(
    [Parameter(ValueFromPipeline = $true)]
    [string]$InputLine
)

begin {
    $hasBuildResult = $false
    $previousProject = $null

    $reset = "`e[0m"
    $dim = "`e[0;2m"

    function Get-Uri {
        param (
            [string]$fullPath,
            [string]$line,
            [string]$column
        )
        $uri = "vscode://file/$($fullPath.Replace('\', '/'))"
        $uri += $line ? ":$line" : ""
        $uri += $line -and $column ? ":$column" : ""
        $uri
    }

    function Get-Hyperlink {
        param (
            [string]$uri,
            [string]$text
        )
        "`e]8;;${uri}`e\${text}`e]8;;`e\" # OSC 8 hyperlink
    }

    Write-Output "`e[0;1;3;94mProcessing...${reset}" # Bold italic bright blue
}

process {
    # Check if this line contains the build result message
    if (-not $hasBuildResult -and $InputLine -match '^Build (?<result>succeeded|FAILED)\.') {
        $hasBuildResult = $true

        $coloredLine = switch ($matches['result']) {
            'succeeded' { "`e[0;1;92m${InputLine}${reset}" } # Bold bright green
            'FAILED' { "`e[0;1;91m${InputLine}${reset}" } # Bold bright red
            default { $InputLine }
        }

        Write-Output "`e[1A`e[2K" # Clear previous line
        Write-Output $coloredLine
        return
    }

    # Skip all lines until the build result message
    if (-not $hasBuildResult) {
        return
    }

    # Matches:
    # - C:\path\to\file.cs(line,column): error CS1234: Message [C:\path\to\project.csproj::TargetFramework=net10.0]
    # - C:\path\to\project.csproj : warning NU1234: Message [C:\path\to\solution.sln]
    if ($InputLine -match @'
(?x) ^
(?<fullPath>
    (?<filePath> .+? [\\/] )
    (?<fileName> [^\\/:]+? )
)
(?<location> \( (?<line>[0-9]+) (?: , (?<column>[0-9]+) )? \) )?
[ ]? : [ ]
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

        if ($project -ne $previousProject) {
            if ($previousProject) {
                Write-Output "" # Add spacing between projects
            }

            $projectHeader = "`e[0;36m" # Cyan

            if ($project -match @'
(?x) ^
(?<projectFullPath>
    (?<projectPath> .+? [\\/] )
    (?<projectName> [^\\/:]+? )
)
(?<projectDetails> :: .+? )?
$
'@) {
                $projectFullPath = $matches['projectFullPath']
                $projectPath = $matches['projectPath']
                $projectName = $matches['projectName']
                $projectDetails = $matches['projectDetails']

                $projectHeader += Get-Hyperlink (Get-Uri $projectFullPath) "${projectPath}`e[1;96m${projectName}" # Bold bright cyan
                $projectHeader += $projectDetails ? "${dim}${projectDetails}" : ""
            }
            else {
                $projectHeader += $project ? $project : "${dim}(none)"
            }

            Write-Output "${projectHeader}${reset}"
            $previousProject = $project
        }

        $fileLink = "${reset}${filePath}"
        $fileLink += Get-Hyperlink (Get-Uri $fullPath $line $column) "`e[1;97m${fileName}" # Bold bright white

        $typeColor = "`e[0;$($type -eq 'error' ? 91 : 93)m" # Red/Yellow

        $typeIcon = switch ($type) {
            'error' { '❌' }
            'warning' { '⚠️' }
            default { ' ' }
        }

        Write-Output "${reset}  ${typeIcon} ${fileLink}${dim}${location}: ${typeColor}${type} ${code}${reset}: ${message}${reset}"
    }
    else {
        if ($InputLine -match '^[ ]{4}[0-9]+ Warning\(s\)$') {
            Write-Output ""
        }

        Write-Output $InputLine
        $previousProject = $null
    }
}

end {
    if (-not $hasBuildResult) {
        Write-Output "`e[1A`e[2K" # Clear "Processing..."
        Write-Output "`e[0;93mNo build result found in output. Please ensure this script is used with the output of a dotnet build command.${reset}"
        exit 1
    }
}
