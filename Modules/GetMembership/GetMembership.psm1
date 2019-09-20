function Get-Membership {
    [CmdletBinding()]
    param(
        [parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string[]]$SamAccountName,

        [string]$Filter,
        [string]$Ignore
    )

    begin {
        $names = [System.Collections.Generic.List[string]]::new()
    }
    process {
        $names.AddRange($SamAccountName)
    }
    end {
        $ldapFilter = "(|$(-join ($names | ForEach-Object { "(samaccountname=$_)" })))"
        Write-Verbose "ldapFilter: $ldapFilter"
        Search-Ad -LdapFilter $ldapFilter -Property 'memberof' |
            ForEach-Object {
                $user = $_.samaccountname
                $_.memberof |
                    ForEach-Object {
                        $group = ($_ -split ',|=')[1]
                        $isFiltered = $group -match $Filter
                        $isIgnored = ($Ignore -ne '') -and ($group -match $Ignore)
                        if ($isFiltered -and !$isIgnored) {
                            [PSCustomObject]@{
                                User  = $user
                                Group = $group
                            }
                        }
                    }
            } | FormatStuff
    }
}

function Get-Membershipoor {
    [CmdletBinding()]
    param([string[]]$UserName)

    process {
        $UserName | ForEach-Object {
            $user = $_
            $groups = dsquery.exe user -samid $user | dsget.exe user -memberof |
                        ForEach-Object { ($_ -split '=|,')[1] } |
                        Where-Object { $null -ne $_ }

            $groups | ForEach-Object {
                $group = $_
                $output = New-Object PSObject
                $output | Add-Member @{ User  = $user }
                $output | Add-Member @{ Group = $group }
                $output
            }
        } | FormatStuff
    }
}

function FormatStuff {
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline)]
        $InputObject
    )

    begin {
        $buffer = @()
    }
    process {
        foreach ($obj in $InputObject) {
            $buffer += $obj
        }
    }
    end {
        $buffer |
            Group-Object -Property Group |
            ForEach-Object {
                $output = New-Object PSObject
                $output | Add-Member @{ Count = $_.Count }
                $output | Add-Member @{ User  = @($_.Group.User) }
                $output | Add-Member @{ Group = $_.Name }
                $output
            } | Sort-Object Count, User, Group # | Format-Table
    }
}

Export-ModuleMember '*-*'
