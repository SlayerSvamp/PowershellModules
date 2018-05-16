#powerkjell-skript skrivet i powerkällaren... powerhouse
function GetMemberOf
{
    param(
        [string[]]$UserName
    )
    
    $UserName |
        ForEach-Object {
        $user = $_
        Get-ADUser -Properties memberof $user |
            select -ExpandProperty memberof |
            Foreach-Object {
                $group = $_
                [PSCustomObject]@{
                    User     = $user
                    MemberOf = ($group -split '=|,')[1]
                }
            }
        } |
        Group-Object -Property MemberOf |
        select `
            Count,
            @{ name = 'Users'; expression = { @($_.Group.User) }},
            @{ name = 'MemberOf'; expression = { $_.Name }}
}

function Get-UserMembership {
    param(
        [string[]]$UserName,
        [switch]$Unsorted
    )

    if ($Unsorted) {
        GetMemberOf -UserName $UserName
    }
    else {
        GetMemberOf -UserName $UserName |
            Sort-Object -Property Count, Users, MemberOf
    }
}

Export-ModuleMember '*-*'
