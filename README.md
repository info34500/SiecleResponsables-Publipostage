# SIECLE Responsables : publipostage Thunderbird

Exemple complet pour envoyer un **courriel personnalisé à chaque famille** (par exemple les
familles des internes) avec **Thunderbird** et l'extension **Mail Merge**, à partir d'un export de
l'application [SiecleResponsables](https://github.com/info34500/SiecleResponsables).

Chaque famille reçoit son propre message : personne ne voit les adresses des autres, et une
adresse partagée par deux parents ne reçoit qu'un seul message.

## Contenu du dépôt

| Fichier | Rôle |
|---|---|
| `Preparer-Publipostage.ps1` | Prépare l'export CSV pour Mail Merge (une ligne par adresse). |
| `Preparer-Publipostage.bat` | Lanceur Windows : glissez le CSV dessus. |
| `modeles/reunion-internat.txt` | Exemple : invitation des familles de l'internat à une réunion. |
| `modeles/coordonnees-a-verifier.txt` | Exemple : demande de vérification des coordonnées. |
| `exemples/internes_FICTIF.csv` | Export **fictif** de SiecleResponsables (internes). |
| `exemples/internes_FICTIF_publipostage.csv` | Le même après `Preparer-Publipostage` : prêt pour Mail Merge. |

## 1. Exporter depuis SiecleResponsables

1. Ouvrez les deux exports SIECLE (Responsables avec adresses, Élèves sans adresse).
2. Filtres :
   - Régime : **Internes (codes 3, 4, 5)** ; Sexe : **Filles** ou **Garçons** si besoin ;
   - Courriel : **Avec un courriel valide** ;
   - **Responsables légaux seulement** : cochée.
3. Export : **une ligne par responsable**, format **CSV** (séparateur et encodage indifférents).
4. **Décochez « En-têtes en clair »** : Mail Merge refuse les espaces dans les noms de colonnes,
   il faut donc les codes (`MEL`, `ELEVE_NOM`…).

## 2. Préparer le fichier

Sous Windows, **glissez le fichier CSV sur `Preparer-Publipostage.bat`**.
Sous Linux : `pwsh ./Preparer-Publipostage.ps1 -Fichier export.csv`.

Le script crée `export_publipostage.csv` à côté du fichier d'origine :

- **une seule ligne par adresse** : deux parents qui partagent une adresse, ou une famille avec
  plusieurs enfants, ne reçoivent qu'un message ;
- les valeurs différentes sont réunies : « Sophie et Paul », « Mère et Père » ;
- nouvelle colonne **`ELEVES`** : « Léa MARTIN (3A) et Tom MARTIN (5B) », et `NB_ELEVES` ;
- les lignes sans courriel valide sont écartées ;
- le fichier est écrit en UTF-8 **sans marqueur (BOM)** et séparé par des **virgules** : c'est ce
  qui évite qu'une première colonne ne soit pas reconnue par Mail Merge.

Comparez `exemples/internes_FICTIF.csv` (3 lignes, dont 2 avec la même adresse) et
`exemples/internes_FICTIF_publipostage.csv` (2 messages).

## 3. Rédiger le message dans Thunderbird

1. Installez l'extension : menu ☰ › **Modules complémentaires** › recherchez **Mail Merge**.
2. Nouveau message. Copiez l'objet et le texte d'un modèle du dossier `modeles/`.
   - **À :** `{{MEL}}`
   - **Objet :** par exemple `Internat – réunion d'information des familles ({{ELEVES}})`
3. Remplacez les `[crochets]` (date, lieu, signature). Les `{{VARIABLES}}` restent telles quelles.
4. Enregistrez le message comme **brouillon** pour pouvoir recommencer en cas d'erreur.

### Variables disponibles

| Variable | Contenu |
|---|---|
| `{{MEL}}` | Adresse du destinataire (champ « À ») |
| `{{ELEVES}}` | Élève(s) concerné(s) avec leur classe |
| `{{NB_ELEVES}}` | Nombre d'élèves concernés |
| `{{ELEVE_PRENOM}}`, `{{ELEVE_NOM}}`, `{{DIVISION}}` | Prénom(s), nom(s), classe(s) |
| `{{SEXE}}`, `{{REGIME}}` | F / M, régime (« Interne »…) |
| `{{CIVILITE}}`, `{{RESP_NOM}}`, `{{RESP_PRENOM}}` | Responsable(s) : « MME et M. », « MARTIN », « Sophie et Paul » |
| `{{LIEN}}`, `{{STATUT_RESP}}` | « Mère et Père », « Responsable légal 1 »… |
| `{{TEL_PORTABLE}}`, `{{TEL_PERSONNEL}}`, `{{TEL_PROFESSIONNEL}}` | Téléphones |
| `{{ADRESSE}}`, `{{CODE_POSTAL}}`, `{{COMMUNE}}`, `{{PAYS}}` | Adresse postale |

Les noms arrivent en majuscules, comme dans SIECLE : c'est pourquoi les modèles commencent par
« Madame, Monsieur, » plutôt que par le nom du parent.

## 4. Lancer le publipostage

1. Dans la fenêtre du message : **Fichier › Mail Merge…**
   - Source : **CSV** ; sélectionnez le fichier `…_publipostage.csv` ;
   - Jeu de caractères : **UTF-8** ; délimiteur : **virgule** ;
   - Envoi : **Envoyer plus tard**.
2. Les messages sont créés dans **Dossiers locaux › Boîte d'envoi**. Ouvrez-en deux ou trois :
   les `{{…}}` doivent être remplacés.
3. Envoyez avec **Fichier › Envoyer les messages en attente**.

**Faites d'abord un essai** : un CSV avec une ou deux lignes (filtrez sur une classe, ou modifiez une
copie du fichier en y mettant votre propre adresse).

En cas d'erreur, supprimez les messages de la boîte d'envoi et relancez depuis le brouillon.

## Bon à savoir

- Mail Merge envoie un message par ligne : 200 familles = 200 envois. Certaines messageries
  limitent le nombre d'envois par heure ; pour une grosse liste, envoyez par classe.
- Les données viennent de SIECLE, qui reste la référence : les corrections signalées par les
  familles se font dans SIECLE.

## Données personnelles

Les fichiers CSV contiennent des données personnelles d'élèves et de leurs familles. Gardez-les sur
un poste ou un espace sécurisé de l'établissement et supprimez-les après l'envoi.
Le `.gitignore` empêche d'enregistrer des CSV dans le dépôt, à l'exception des exemples **fictifs**.

## Licence

Distribué sous licence MIT : voir le fichier [LICENSE](LICENSE).
