function Compare-FileHashFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string]$First,

        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string]$Second,

        #todo: make this parameter dynamic
        [ValidateSet('MACTripleDES', 'MD5', 'RIPEMD160', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
        [string]$Algorithm = 'MD5'
    )

    $gciParam = @{
        File        = $true
        Recurse     = $true
        ErrorAction = 'SilentlyContinue'
    }
    
    #todo: make function
    $firstFileHash = @{}
    Get-ChildItem @gciParam -Path $First | ForEach-Object { $name = $_.FullName -replace [regex]::Escape((Resolve-Path $First).Path), '.'; $firstFileHash[$name] = (Get-FileHash -Path $_.FullName -Algorithm $Algorithm).Hash }
    $secondFileHash = @{}
    Get-ChildItem @gciParam -Path $Second | ForEach-Object { $name = $_.FullName -replace [regex]::Escape((Resolve-Path $Second).Path), '.'; $secondFileHash[$name] = (Get-FileHash -Path $_.FullName -Algorithm $Algorithm).Hash }

    $uniqueFilenames = ($firstFileHash.Keys + $secondFileHash.Keys) | select -Unique
    $uniqueFilenames | ForEach-Object {
        [PSCustomObject]@{
            Name   = $_
            First  = $firstFileHash[$_]
            Second = $secondFileHash[$_]
            Eq     = $firstFileHash[$_] -eq $secondFileHash[$_]
        }
    }
}
