<#
   NOTES
   ===========================================================================
    Created with:  Visual Studio Code
    Created on:    $(date)
    Created by:    Calvin Kohler-Katz
    Organization:  
    Filename:      file_size_report.ps1
   ===========================================================================
   DESCRIPTION
       Report file sizes to the nearest cluster size.
#>
param(
    # Directory. Default = Working directory
    [string]
    $SourceDir = $PSScriptRoot
)

function Write-Percentage ($label, $count) {
    Write-Host ($label + ': ') -NoNewline

    $perc = [math]::Round(($count / $total) * 100)
    Write-Host '[' -NoNewline
    for($x = 0; $x -lt $perc; $x++) {
        Write-Host '*' -NoNewline
    }
    for($x = 0; $x -lt (100-$perc); $x++) {
        Write-Host '-' -NoNewline
    }
    Write-Host ']'
}


$table = @{
    '4KB'   = 0;
    '8KB'   = 0;
    '16KB'  = 0;
    '32KB'  = 0;
    '64KB'  = 0;
    '128KB' = 0;
    '256KB' = 0;
    'LARGE' = 0;
}

$table_obj = New-Object -TypeName PSObject -Property $table

$files = Get-ChildItem -Recurse -File -Path $SourceDir -ErrorAction SilentlyContinue
$total = $files.Count

foreach ($file in $files) {
    $file_size = [math]::Ceiling($file.Length / 1KB)

    if ($file_size -gt 256) {
        $table.LARGE++
    }
    elseif ($file_size -gt 128) {
        $table.'256KB'++
    }
    elseif ($file_size -gt 64) {
        $table.'128KB'++
    }
    elseif ($file_size -gt 32) {
        $table.'64KB'++
    }
    elseif ($file_size -gt 16) {
        $table.'32KB'++
    }
    elseif ($file_size -gt 8) {
        $table.'16KB'++
    }
    elseif ($file_size -gt 4) {
        $table.'8KB'++
    }
    else {
        $table.'4KB'++
    }
}

"Total files found: " + $files.Count
" "
Write-Percentage ">256KB" $table.'LARGE'
Write-Percentage " 256KB" $table.'256KB'
Write-Percentage " 128KB" $table.'128KB'
Write-Percentage "  64KB" $table.'64KB'
Write-Percentage "  32KB" $table.'32KB'
Write-Percentage "  16KB" $table.'16KB'
Write-Percentage "   8KB" $table.'8KB'
Write-Percentage "   4KB" $table.'4KB'
" "
">256KB: " + $table.'LARGE'
" 256KB: " + $table.'256KB'
" 128KB: " + $table.'128KB'
"  64KB: " + $table.'64KB'
"  32KB: " + $table.'32KB'
"  16KB: " + $table.'16KB'
"   8KB: " + $table.'8KB'
"   4KB: " + $table.'4KB'
" "