function Search-Ad {
    [CmdletBinding()]
    param(
        [parameter(
            ParameterSetName = 'LdapFilter',
            Mandatory = $true,
            HelpMessage = 'Enter an LDAP search string.',
            ValueFromPipeline = $true
        )]
        [string[]]$LdapFilter,

        [parameter(
            ParameterSetName = 'SamAccountName',
            Mandatory = $true,
            HelpMessage = 'Enter a sAMAccountName.',
            ValueFromPipeline = $true
        )]
        [string[]]$SamAccountName,

        [parameter(
            ParameterSetName = 'Mail',
            Mandatory = $true,
            HelpMessage = 'Enter a mail address.',
            ValueFromPipeline = $true
        )]
        [string[]]$Mail,

        [Alias('Properties')]
        [string[]]$Property
    )

    begin {
        $adModuleAvailable = (Get-Module -ListAvailable 'ActiveDirectory') -ne $null
        Write-Verbose "Module 'ActiveDirectory' available: $adModuleAvailable"
        
        Write-Verbose "Parameter set: '$($PSCmdlet.ParameterSetName)'"

        $defaultDisplayProperties = 'givenname', 'sn', 'displayname', 'mail', 'mobile', 'samaccountname', 'company', 'l', 'distinguishedname'
        Write-Verbose "Default display properties: $defaultDisplayProperties"
        Write-Verbose "Additional properties: $Property"

        if ($Property -eq '*') {
            $propertiesToLoad = $null
        }
        else {
            $defaultDisplayProperties += $Property
            $propertiesToLoad = $defaultDisplayProperties
        }
    }
    process {
        $searchString = ($LdapFilter, $SamAccountName, $Mail -ne $null)[0]
        Write-Verbose "Searchstring: [$($searchString -join ', ')]"
        foreach ($search in $searchString) {
            $ldap = switch ($PSCmdlet.ParameterSetName) {
                'LdapFilter' {
                    $search
                }
                'SamAccountName' {
                    "(samaccountname=$search)"
                }
                'Mail' {
                    "(proxyaddresses=smtp:$search)"
                }
                default {
                    'unknown parameter set'
                }
            }
            
            Write-Verbose "LDAP search string for '$search': '$ldap'"

            $dirSearch = [System.DirectoryServices.DirectorySearcher]::new($ldap)
            #all properties are loaded by default unless .PropertiesToLoad.Add() is used
            if ($propertiesToLoad) {
                $propertiesToLoad | ForEach-Object { [void]$dirSearch.PropertiesToLoad.Add($_) }
            }
            
            $dirSearch.FindAll() |
                ForEach-Object {
                    $output = [PSCustomObject]@{}
                    $noteProperties = @{}
                    foreach ($prop in $_.Properties.GetEnumerator()) {
                        $key = $prop.Key
                        $value = $prop.Value | ForEach-Object { $_ }
                        $noteProperties[$key] = $value
                    }
                    
                    $output | Add-Member $noteProperties -PassThru
                    #$displayProperties = $output.psobject.properties.Name.Where({ $_ -in $defaultDisplayProperties })
                    #$displayProperties = $defaultDisplayProperties
                    #$output | Set-DefaultDisplayPropertySet -Property $displayProperties -PassThru
                }
        }
    }
    end {}
}

Export-ModuleMember '*-*'
