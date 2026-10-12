# Verifikasi dependency rule (modul Minggu 7 - Clean Architecture).
#
# Padanan `rg` pada modul, ditulis dengan PowerShell karena ripgrep tidak
# tersedia di lingkungan Windows ini. Jalankan dari folder project:
#
#   powershell -ExecutionPolicy Bypass -File tool/check_dependency_rule.ps1
#
# Semua pemeriksaan harus menghasilkan "(NOL HASIL)".

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Invoke-Check {
    param(
        [string]$Title,
        [string]$Pattern,
        [string[]]$Paths
    )

    Write-Output "================================================================"
    Write-Output "# $Title"
    Write-Output "pattern : $Pattern"
    Write-Output "path    : $($Paths -join ', ')"
    Write-Output "----------------------------------------------------------------"

    $files = Get-ChildItem -Recurse -Path $Paths -Filter *.dart -ErrorAction SilentlyContinue
    $hits = @($files | Select-String -Pattern $Pattern)

    if ($hits.Count -eq 0) {
        Write-Output "(NOL HASIL) - lolos"
    }
    else {
        Write-Output "($($hits.Count) HASIL) - GAGAL"
        foreach ($hit in $hits) {
            $relative = Resolve-Path -Relative $hit.Path
            Write-Output "  ${relative}:$($hit.LineNumber): $($hit.Line.Trim())"
        }
    }
    Write-Output ""
}

Invoke-Check `
    -Title 'GREP 1 - presentation steril dari akses data mentah' `
    -Pattern 'Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode' `
    -Paths @('lib\features\*\presentation', 'lib\pages')

Invoke-Check `
    -Title 'GREP 2 - domain & core steril dari framework/package' `
    -Pattern "import 'package:(flutter|dio|sqflite|firebase)" `
    -Paths @('lib\features\*\domain', 'lib\core')

Invoke-Check `
    -Title 'GREP 3 - UI (pages/widgets) tidak menginstansiasi repository/Dio sendiri' `
    -Pattern 'RepositoryImpl\(|Repository\(|Dio\(BaseOptions' `
    -Paths @('lib\features\*\presentation\pages', 'lib\features\*\presentation\widgets', 'lib\pages')

Write-Output "CATATAN: folder presentation\providers SENGAJA tidak diperiksa GREP 3."
Write-Output "Modul Minggu 7 menempatkan wiring DI di provider (contoh resmi modul:"
Write-Output "`NoteRepositoryImpl(openDb: openNotesDb)` di notes_providers.dart)."
Write-Output "Yang dilarang adalah widget/notifier membuat dependensi sendiri,"
Write-Output "sehingga pemeriksaan diarahkan ke pages/ dan widgets/."
