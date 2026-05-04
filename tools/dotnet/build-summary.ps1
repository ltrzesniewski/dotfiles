#
# Pipeline which processes the output of a "dotnet build/test" command and outputs only the summary,
# including hyperlinks for errors and warnings that open in VS Code.
#
# Helps with large refactorings.
#

param(
    [switch]$Short
)

begin {
    $script:hasBuildResult = $false
    $script:failedBuilds = @{}
    $script:hasTestResult = $false
    $script:previousProject = $null

    $reset = "`e[0m"
    $dim = "`e[0;2m"
    $brightRed = "`e[0;91m"
    $brightYellow = "`e[0;93m"

    function Get-Uri {
        param (
            [string]$fullPath,
            [int]$line,
            [int]$column
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
}

process {
    $inputLine = $_

    if (-not $script:hasBuildResult) {
        if (!$Short -and $inputLine -match '^  (?<project>[\w-.]+) -> ') {
            # Build success
            $project = $matches['project']
            $tfm = $inputLine -match '-> .*[/\\](?:Debug|Release)[/\\](?<tfm>net[\w.]+)[/\\]' ? " $($matches['tfm'])" : ''
            Write-Output "${reset}  ✅ 🔨 ${project}${dim}${tfm}${reset}"
        }
        elseif (!$Short -and $inputLine -match ' error \w+:.* \[.*?[/\\](?<project>[^/\\]+?)\.(?:\w*proj)(?<projectDetails>::[^\]]*)?\]$') {
            # Build error
            $project = $matches['project']
            $tfm = $matches['projectDetails'] -match '\bTargetFramework=(?<tfm>net[\w.]+)' ? " $($matches['tfm'])" : ''
            $errorKey = "${project}/${tfm}"
            if ($errorKey -notin $script:failedBuilds.Keys) {
                $script:failedBuilds[$errorKey] = $true
                Write-Output "${reset}  ❌ 🔨 ${brightRed}${project}${dim}${tfm}${reset}"
            }
        }
        elseif (!$Short -and $inputLine -match '^(?<result>Passed|Failed)!\s*-\s*Failed:\s*(?<failed>\d+),\s*Passed:\s*(?<passed>\d+),\s*Skipped:\s*(?<skipped>\d+),\s*Total:\s*(?<total>\d+),\s*Duration:\s*(?<duration>.+?)\s*-\s*(?<project>.*?)\.(?:dll|exe)(?:\s+\((?<tfm>net[\w.]+)\))?') {
            # Test result
            $script:hasTestResult = $true
            $success = $matches['result'] -eq 'Passed'
            $project = $matches['project']
            $failed = $matches['failed']
            $passed = $matches['passed']
            $skipped = $matches['skipped']
            $duration = $matches['duration'] -replace '(?<=\d)\s+', ''
            $tfm = $matches['tfm'] ? " $($matches['tfm'])" : ''
            Write-Output "${reset}  $($success ? '✅' : "❌${brightRed}") 🧪 ${project}${dim}${tfm} - ${dim}${passed} passed$($failed -ne '0' ? ", ${failed} failed" : '')$($skipped -ne '0' ? ", ${skipped} skipped" : '') in ${duration}${reset}"
        }
        elseif ($inputLine -match '^Build (?<result>succeeded|FAILED)\.') {
            # Final build result
            $script:hasBuildResult = $true
            $coloredLine = switch ($matches['result']) {
                'succeeded' { "`e[0;1;92m${inputLine}${reset}" } # Bold bright green
                'FAILED' { "`e[0;1;91m${inputLine}${reset}" } # Bold bright red
                default { $inputLine }
            }

            Write-Output ""
            Write-Output $coloredLine
            Write-Progress -Completed
            return
        }

        # Hack the progress bar to show the last log line
        Write-Progress -Activity 'Build' -Status "`e[2K`r${reset}  $($inputLine.Trim())"
        return
    }

    # Matches:
    # - C:\path\to\file.cs(line,column): error CS1234: Message [C:\path\to\project.csproj::TargetFramework=net10.0]
    # - C:\path\to\project.csproj : warning NU1234: Message [C:\path\to\solution.sln]
    if ($inputLine -match @'
(?x) ^
(?<fullPath>
    (?<filePath> .+? [\\/] )
    (?<fileName> [^\\/:]+? )
)
(?<location> \( (?<line>[0-9]+) (?: , (?<column>[0-9]+) )? \) )?
[ ]? : [ ]
(?<type>error|warning)
[ ]
(?<code> \w+ )
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

        if ($project -ne $script:previousProject) {
            if ($script:previousProject) {
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
            $script:previousProject = $project
        }

        $fileLink = "${reset}${filePath}"
        $fileLink += Get-Hyperlink (Get-Uri $fullPath $line $column) "`e[1;97m${fileName}" # Bold bright white

        $typeColor = $type -eq 'error' ? $brightRed : $brightYellow

        $typeIcon = switch ($type) {
            'error' { '❌' }
            'warning' { '⚠️' }
            default { ' ' }
        }

        Write-Output "${reset}  ${typeIcon} ${fileLink}${dim}${location}: ${typeColor}${type} ${code}${reset}: ${message}${reset}"
    }
    else {
        if ($inputLine -match '^[ ]{4}[0-9]+ Warning\(s\)$') {
            Write-Output ""
        }

        Write-Output $inputLine
        $script:previousProject = $null
    }
}

end {
    if (-not $script:hasBuildResult -and -not $script:hasTestResult -and $script:failedBuilds.Count -eq 0) {
        Write-Output ""
        Write-Output "${brightYellow}No build or test result found in output. Please ensure this script is used with the output of a dotnet build or test command.${reset}"
        exit 1
    }
}
