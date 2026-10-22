#requires -Version 5.1
<#
    Preparer-Publipostage.ps1
    Prépare un export CSV de SiecleResponsables pour l'extension Mail Merge de Thunderbird :
      - une seule ligne par adresse courriel : deux parents qui partagent la même adresse,
        ou une famille avec plusieurs enfants, ne reçoivent qu'un message ;
      - les valeurs différentes sont réunies (« Sophie et Paul », « Mère et Père ») ;
      - nouvelle colonne ELEVES : « Léa MARTIN (3A) et Tom MARTIN (5B) » ;
      - lignes sans courriel valide écartées ;
      - fichier écrit en UTF-8 sans marqueur (BOM), séparé par des virgules.

    Utilisation :
      - Windows : glissez le fichier CSV sur « Preparer-Publipostage.bat » ;
      - ou : powershell -ExecutionPolicy Bypass -File .\Preparer-Publipostage.ps1 -Fichier export.csv
      - Linux : pwsh ./Preparer-Publipostage.ps1 -Fichier export.csv
    Le résultat est écrit à côté : export_publipostage.csv
#>
param(
    [Parameter(Mandatory, Position = 0)][string]$Fichier,
    [string]$Sortie = ''
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Fichier)) { throw "Fichier introuvable : $Fichier" }
$Fichier = (Resolve-Path -LiteralPath $Fichier).Path
if (-not $Sortie) {
    $Sortie = Join-Path ([System.IO.Path]::GetDirectoryName($Fichier)) (([System.IO.Path]::GetFileNameWithoutExtension($Fichier)) + '_publipostage.csv')
}

# --- Lecture : UTF-8 (avec ou sans BOM), sinon Windows-1252 (export « ANSI »)
$octets = [System.IO.File]::ReadAllBytes($Fichier)
try {
    $texte = (New-Object System.Text.UTF8Encoding($false, $true)).GetString($octets)
}
catch {
    try { $ansi = [System.Text.Encoding]::GetEncoding(1252) }
    catch {
        [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)
        $ansi = [System.Text.Encoding]::GetEncoding(1252)
    }
    $texte = $ansi.GetString($octets)
}
$texte = $texte.TrimStart([char]0xFEFF)

# --- Séparateur deviné d'après la ligne d'en-tête
$entete = ($texte -split "`r?`n", 2)[0]
$separateur = ','
foreach ($candidat in ';', "`t", ',') { if ($entete.Contains($candidat)) { $separateur = $candidat; break } }

$lignes = @($texte | ConvertFrom-Csv -Delimiter $separateur)
if ($lignes.Count -eq 0) { throw 'Le fichier ne contient aucune ligne.' }
$colonnes = @($lignes[0].PSObject.Properties | ForEach-Object { $_.Name })

if ($colonnes -notcontains 'MEL') {
    $conseil = if ($colonnes -contains 'Courriel') {
        "Le fichier a été exporté avec « En-têtes en clair » : décochez cette case dans SiecleResponsables, puis exportez à nouveau."
    } else {
        "Exportez depuis SiecleResponsables en « une ligne par responsable », case « En-têtes en clair » décochée."
    }
    throw "Colonne MEL introuvable. $conseil"
}

# --- Regroupement par adresse (sans tenir compte des majuscules)
$motif = '^[^@\s;,<>"]+@[^@\s;,<>"]+\.[^@\s;,<>".]{2,}$'
$groupes = [ordered]@{}
$ecartees = 0
foreach ($ligne in $lignes) {
    $mel = ([string]$ligne.MEL).Trim()
    $valide = ($mel -match $motif)
    if ($colonnes -contains 'MEL_STATUT' -and [string]$ligne.MEL_STATUT -ne 'Valide') { $valide = $false }
    if (-not $valide) { $ecartees++; continue }
    $cle = $mel.ToLowerInvariant()
    if (-not $groupes.Contains($cle)) { $groupes[$cle] = New-Object System.Collections.Generic.List[object] }
    $groupes[$cle].Add($ligne)
}

function Join-Valeurs([string[]]$Valeurs) {
    $uniques = New-Object System.Collections.Generic.List[string]
    foreach ($v in $Valeurs) {
        $v = ([string]$v).Trim()
        if ($v -and -not $uniques.Contains($v)) { $uniques.Add($v) }
    }
    if ($uniques.Count -le 1) { return ($uniques -join '') }
    return (($uniques[0..($uniques.Count - 2)] -join ', ') + ' et ' + $uniques[$uniques.Count - 1])
}

$colonnesSortie = @('MEL') + @($colonnes | Where-Object { $_ -ne 'MEL' }) + @('ELEVES', 'NB_ELEVES')
$resultat = New-Object System.Collections.Generic.List[object]
foreach ($cle in $groupes.Keys) {
    $groupe = $groupes[$cle]
    $sortieLigne = [ordered]@{ MEL = ([string]$groupe[0].MEL).Trim() }
    foreach ($c in $colonnes) {
        if ($c -eq 'MEL') { continue }
        $sortieLigne[$c] = Join-Valeurs @($groupe | ForEach-Object { [string]$_.$c })
    }
    $eleves = @($groupe | ForEach-Object {
        $nom = ((@([string]$_.ELEVE_PRENOM, [string]$_.ELEVE_NOM) | Where-Object { $_ }) -join ' ')
        if ([string]$_.DIVISION) { $nom += " ($([string]$_.DIVISION))" }
        $nom
    })
    $sortieLigne['ELEVES'] = Join-Valeurs $eleves
    $sortieLigne['NB_ELEVES'] = [string](@($eleves | Where-Object { $_ } | Select-Object -Unique).Count)
    $resultat.Add([pscustomobject]$sortieLigne)
}

# --- Écriture : UTF-8 sans BOM, virgules, guillemets si nécessaire
$proteger = {
    param([string]$v)
    if ($v.IndexOf(',') -ge 0 -or $v.IndexOf('"') -ge 0 -or $v.IndexOf("`n") -ge 0 -or $v.IndexOf("`r") -ge 0) {
        return '"' + $v.Replace('"', '""') + '"'
    }
    return $v
}
$sb = New-Object System.Text.StringBuilder
[void]$sb.Append(($colonnesSortie -join ',')).Append("`r`n")
foreach ($l in $resultat) {
    [void]$sb.Append((@($colonnesSortie | ForEach-Object { & $proteger ([string]$l.$_) }) -join ',')).Append("`r`n")
}
[System.IO.File]::WriteAllText($Sortie, $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))

Write-Host "Lignes lues           : $($lignes.Count)"
Write-Host "Sans courriel valide  : $ecartees (écartées)"
Write-Host "Adresses distinctes   : $($resultat.Count) message(s) à envoyer" -ForegroundColor Green
Write-Host "Fichier pour Mail Merge : $Sortie"
