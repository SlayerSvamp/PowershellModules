#powerkjell-skript skrivet i powerkällaren... powerhouse
function Get-Membership {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$SamAccountName,
        [string]$Filter,
        [string]$Ignore
    )

    begin {
        $names = New-Object System.Collections.Generic.List[System.String]
    }
    process {
        $names.AddRange($SamAccountName)
    }
    end {
        $ldapFilter = "(|$( -join ($names | ForEach-Object { "(samaccountname=$_)"})))"
        $splat = @{
            Properties = 'MemberOf', 'SamAccountName'
            LDAPFilter = $ldapFilter
        }

        Get-ADObject @splat |
            Foreach-Object {
                $user = $_.SamAccountName
                $_.MemberOf | 
                    ForEach-Object {
                        $group = ($_ -split '=|,')[1]
                        $isIgnored = $Ignore -and ($group -match $Ignore)
                        $isFiltered = $group -match $Filter
                        if($isFiltered -and -not $isIgnored) {
                            [PSCustomObject]@{
                                User     = $user
                                MemberOf = $group
                            }
                        }
                    }
            } |
            Group-Object -Property MemberOf |
                ForEach-Object {
                    [PSCustomObject] @{
                        Count = $_.Count
                        Member = $_.Group.User
                        Group = $_.Name
                    }
                } |
                Sort-Object -Property Count, Member, Group
    }
}

Export-ModuleMember '*-*'
