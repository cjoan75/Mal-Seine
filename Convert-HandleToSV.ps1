<#
.SYNOPSIS
Convert-HandleToSV.ps1 takes the output from Sysinternals handle.exe -a and parses
it into delimited format suitable for stack ranking via get-stakrank.ps1.

NOTE:
Handle Ids are discarded and remaining lines are deduped.

.PARAMETER FileNamePattern
Specifies the naming pattern common to the handle file output to be converted.
.PARAMETER Delimiter
Specifies the delimiter character to use for output. Tab is default.
.PARAMETER ToFile
Specifies that output be written to a file matching the FileNamePattern (same path),
but with .tsv or .csv extension depending on delimtier (.tsv is default).
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [string]$FileNamePattern,
    [Parameter(Mandatory=$False,Position=1)]
        [string]$Delimiter="`t",
    [Parameter(Mandatory=$False,Position=2)]
        [switch]$tofile=$False
)

function Convert {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$File,
    [Parameter(Mandatory=$True,Position=1)]
        [char]$Delimiter
)
    Write-Verbose "Entering $($MyInvocation.MyCommand)"
    Write-Verbose "Processing $File."
    $data = gc $File | select -skip 6
    ("Process","PId","Owner","Type","Perms","Name") -join $Delimiter
    foreach($line in $data) {
        $line = $line.Trim()
        if ($line -match " pid: ") {
            $HandleId = $Type = $Perms = $Name = $null
            $pattern = "(?<ProcessName>^[-a-zA-Z0-9_.]+) pid: (?<PId>\d+) (?<Owner>.+$)"
            if ($line -match $pattern) {
                $ProcessName,$ProcId,$Owner = ($matches['ProcessName'],$matches['PId'],$matches['Owner'])
            }
        } else {
            $pattern = "(?<HandleId>^[a-f0-9]+): (?<Type>\w+)"
            if ($line -match $pattern) {
                $HandleId,$Type = ($matches['HandleId'],$matches['Type'])
                $Perms = $Name = $null
                switch ($Type) {
                    "File" {
                        $pattern = "(?<HandleId>^[a-f0-9]+):\s+(?<Type>\w+)\s+(?<Perms>\([-RWD]+\))\s+(?<Name>.*)"
                        if ($line -match $pattern) {
                            $Perms,$Name = ($matches['Perms'],$matches['Name'])
                        }
                    }
                    default {
                        $pattern = "(?<HandleId>^[a-f0-9]+):\s+(?<Type>\w+)\s+(?<Name>.*)"
                        if ($line -match $pattern) {
                            $Name = ($matches['Name'])
                        }
                    }
                }
                if ($Name -ne $null) {
                    # ($ProcessName,$ProcId,$Owner,$HandleId,$Type,$Perms,$Name) -join $Delimiter
                    ($ProcessName,$ProcId,$Owner,$Type,$Perms,$Name) -join $Delimiter
                }
            }
        }
    }
}

. .\mal-seine-common.ps1

Convert-Main -FileNamePattern $FileNamePattern -Delimiter $Delimiter -tofile $tofile