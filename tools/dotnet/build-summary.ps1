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
    enum Phase {
        Execution
        BuildSummary
        TestSummary
    }

    $script:currentPhase = [Phase]::Execution
    $script:failedBuilds = @{}
    $script:hasTestResult = $false
    $script:previousProject = $null
    $script:mtpResult = $null

    $reset = "`e[0m"
    $dim = "`e[0;2m"
    $green = "`e[0;32m"
    $red = "`e[0;31m"
    $brightRed = "`e[0;91m"
    $brightYellow = "`e[0;93m"
    $boldBrightGreen = "`e[0;1;92m"
    $boldBrightRed = "`e[0;1;91m"

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

    switch ($script:currentPhase) {
        ([Phase]::Execution) {
            if (!$Short -and $inputLine -match '^  (?<project>[\w-.]+) -> ') {
                # Build success
                $project = $matches['project']
                $tfm = $inputLine -match '-> .*[/\\](?:Debug|Release)[/\\](?<tfm>net[\w.-]+)[/\\]' ? " $($matches['tfm'])" : ''
                Write-Output "${reset}  ✅ 🔨 ${project}${dim}${tfm}${reset}"
            }
            elseif (!$Short -and $inputLine -match ' error \w+:.* \[.*?[/\\](?<project>[^/\\]+?)(_[a-z0-9]{8}_wpftmp)?\.(?:\w*proj)(?<projectDetails>::[^\]]*)?\]$') {
                # Build error
                $project = $matches['project']
                $tfm = $matches['projectDetails'] -match '\bTargetFramework=(?<tfm>net[\w.]+)' ? " $($matches['tfm'])" : ''
                $errorKey = "${project}/${tfm}"
                if ($errorKey -notin $script:failedBuilds.Keys) {
                    $script:failedBuilds[$errorKey] = $true
                    Write-Output "${reset}  ❌ 🔨 ${brightRed}${project}${dim}${tfm}${reset}"
                }
            }
            elseif (!$Short -and $inputLine -match '[/\\](?<project>[^/\\]*?)\.(?:dll|exe) \((?<tfm>net[\w.]+)\|\w+\) (?<result>passed|failed with (?<failed>\d+) error\(s\)) \((?<duration>.*)\)$') {
                # Microsoft.Testing.Platform result
                $script:hasTestResult = $true
                $success = $matches['result'] -eq 'passed'
                $project = $matches['project']
                $failed = $matches['failed']
                $duration = $matches['duration'] -replace ' \d+ms\b', ''
                $tfm = $matches['tfm'] ? " $($matches['tfm'])" : ''
                Write-Output "${reset}  $($success ? '✅' : "❌${brightRed}") 🧪 ${project}${dim}${tfm} - $($success ? 'passed' : "${failed} failed") in ${duration}${reset}"
            }
            elseif (!$Short -and $inputLine -match '^(?<result>Passed|Failed)!\s*-\s*Failed:\s*(?<failed>\d+),\s*Passed:\s*(?<passed>\d+),\s*Skipped:\s*(?<skipped>\d+),\s*Total:\s*(?<total>\d+),\s*Duration:\s*(?<duration>.+?)\s*-\s*(?<project>.*?)\.(?:dll|exe)(?:\s+\((?<tfm>net[\w.]+)\))?') {
                # VSTest result
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
                $script:currentPhase = [Phase]::BuildSummary
                $coloredLine = switch ($matches['result']) {
                    'succeeded' { "${boldBrightGreen}${inputLine}${reset}" }
                    'FAILED' { "${boldBrightRed}${inputLine}${reset}" }
                    default { $inputLine }
                }

                Write-Output ""
                Write-Output $coloredLine
                Write-Progress -Completed
                return
            }
            elseif ($inputLine -match '^Test run summary: (?<result>Passed|Failed)!') {
                # Final MTF summary
                $script:currentPhase = [Phase]::TestSummary
                $coloredLine = switch ($matches['result']) {
                    'Passed' { $script:mtpResult = $true; "${boldBrightGreen}${inputLine}${reset}" }
                    'Failed' { $script:mtpResult = $false; "${boldBrightRed}${inputLine}${reset}" }
                    default { $inputLine }
                }

                Write-Output ""
                Write-Output $coloredLine
                Write-Output ""
                Write-Progress -Completed
                return
            }

            # Hack the progress bar to show the last log line
            Write-Progress -Activity 'Build' -Status "`e[2K`r${reset}  $($inputLine.Trim())"
            return
        }

        ([Phase]::BuildSummary) {
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
    [ ] \[
      (?<project> [^[]+? )
    \]
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
(?:
    (?<projectPath> .+? [\\/] )
    (?<projectName> [^\\/:]+? )
)
(?<projectDetails> :: .+? )?
$
'@) {
                        $projectPath = $matches['projectPath']
                        $projectName = $matches['projectName'] -replace '_[a-z0-9]{8}_wpftmp(?<extension>\.[a-z]*proj)$', '${extension}'
                        $projectFullPath = "${projectPath}${projectName}"
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

        ([Phase]::TestSummary) {
            if ($mtpResult -eq $true -and $inputLine -match '^  succeeded: \d+$') {
                Write-Output "${green}${inputLine}${reset}"
            }
            elseif ($mtpResult -eq $false -and $inputLine -match '^  failed: \d+$') {
                Write-Output "${red}${inputLine}${reset}"
            }
            elseif ($inputLine -match '^Test run completed with non-success exit code') {
                Write-Output ""
                Write-Output "${dim}${inputLine}${reset}"
            }
            else {
                Write-Output $inputLine
            }
        }

        default {
            # Shouldn't happen
            Write-Output $inputLine
        }
    }
}

end {
    if ($script:currentPhase -eq [Phase]::Execution -and -not $script:hasTestResult -and $script:failedBuilds.Count -eq 0) {
        Write-Output ""
        Write-Output "${brightYellow}No build or test result found in output. Please ensure this script is used with the output of a dotnet build or test command.${reset}"
        exit 1
    }
}
