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
    begin {
        $gciParam = @{
            File        = $true
            Recurse     = $true
        }
    }
    process {
        #todo: make function
        $firstFileHash = @{}
        Get-ChildItem @gciParam -Path $First | ForEach-Object { $name = $_.FullName -replace [regex]::Escape((Resolve-Path $First).Path), '.'; $firstFileHash[$name] = (Get-FileHash -Path $_.FullName -Algorithm $Algorithm).Hash }
        $secondFileHash = @{}
        Get-ChildItem @gciParam -Path $Second | ForEach-Object { $name = $_.FullName -replace [regex]::Escape((Resolve-Path $Second).Path), '.'; $secondFileHash[$name] = (Get-FileHash -Path $_.FullName -Algorithm $Algorithm).Hash }
    }
    end {
        $uniqueFilenames = ($firstFileHash.Keys + $secondFileHash.Keys) | select -Unique
        $uniqueFilenames | ForEach-Object {
            [PSCustomObject]@{
                Name    = $_
                First   = $firstFileHash[$_]
                Second  = $secondFileHash[$_]
                Compare = $(
                    if($firstFileHash[$_]) {
                        if($secondFileHash[$_]) {
                            if($firstFileHash[$_] -eq $secondFileHash[$_]){ 'Equal' }
                            else { 'Not equal' }
                        }
                        else { 'Only first' }
                    }
                    else { 'Only second' }
                )
            }
        }
    }
}

Export-ModuleMember '*-*'