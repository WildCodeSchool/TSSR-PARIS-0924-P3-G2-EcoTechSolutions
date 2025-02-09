param (
    [string]$CsvFilePath = "C:\chemin\vers\fichier.csv"
)

# Vérifier si le fichier CSV existe
if (!(Test-Path -Path $CsvFilePath)) {
    Write-Error "Le fichier CSV spécifié n'existe pas : $CsvFilePath"
    exit 1
}

# Importer le fichier CSV
$computers = Import-Csv -Path $CsvFilePath

foreach ($computer in $computers) {
    # Extraire les informations du fichier CSV et gérer les champs vides
    $site = if ([string]::IsNullOrWhiteSpace($computer.Site)) { "NonSpécifié" } else { $computer.Site }
    $department = if ([string]::IsNullOrWhiteSpace($computer.Departement)) { "NonSpécifié" } else { $computer.Departement }
    $service = if ([string]::IsNullOrWhiteSpace($computer.Service)) { "NonSpécifié" } else { $computer.Service }
    $function = if ([string]::IsNullOrWhiteSpace($computer.Fonction)) { "NonSpécifié" } else { $computer.Fonction }
    $computerName = if ([string]::IsNullOrWhiteSpace($computer."Nommage")) {
        Write-Warning "Nom d'ordinateur manquant. Ligne ignorée."
        continue
    } else {
        $computer."Nommage"
    }

    # Construire le chemin de l'OU
    $ouPath = "OU=$function,OU=$service,OU=$department,OU=$site,OU=OU_Ordinateurs,DC=ecotechsolutions,DC=lan"

    # Vérifier si l'ordinateur existe déjà dans le domaine
    $existingComputer = Get-ADComputer -Filter { Name -eq $computerName } -ErrorAction SilentlyContinue

    if ($existingComputer) {
        Write-Output "L'ordinateur $computerName existe déjà dans le domaine."
    } else {
        # Ajouter l'ordinateur dans le domaine et le placer dans la bonne OU
        try {
            New-ADComputer -Name $computerName -SamAccountName $computerName -Path $ouPath -Description "$site - $function"
            Write-Output "L'ordinateur $computerName a été ajouté dans l'OU $ouPath."
        } catch {
            Write-Error "Erreur lors de l'ajout de l'ordinateur $computerName : $_"
        }
    }
}
