# Système de Gestion des Notes (SGN)

**Projet de fin de semestre — Master 1 Informatique**
**Module : Théorie des Langages & Compilation**
**Année académique : 2025–2026**
**Université Gaston Berger — Institut Polytechnique de Saint-Louis (IPSL)**

---

## Présentation

Le SGN est un compilateur dédié à l'analyse de fichiers de notes étudiantes au format `.sgn`. Il est composé de :

- Un **analyseur lexical** (Flex) qui tokenise le fichier source
- Un **analyseur syntaxique et sémantique** (Bison) qui vérifie la grammaire et calcule les résultats
- Une **interface graphique** (Python/Tkinter) qui affiche les résultats et les erreurs
- Un **AST** et une **table de symboles** pour la représentation interne des données

Le binaire C lit un fichier `.sgn` et produit un flux **JSON sur stdout**, lu par l'interface Python via `subprocess`.

---

## Arborescence du projet

```
sgn_project/
├── src/
│   ├── lexer.l          # Analyseur lexical Flex
│   ├── parser.y         # Analyseur syntaxique Bison
│   ├── ast.h / ast.c    # Arbre Syntaxique Abstrait
│   ├── symboles.h       # Structures de données + table de symboles
│   ├── symboles.c       # Implémentation de la table de symboles
│   ├── main.c           # Point d'entrée du programme
│   └── Makefile         # Compilation automatique
│
├── gui/
│   ├── app.py           # Application Python principale
│   ├── interface.py     # Widgets Tkinter
│   └── parser_bridge.py # Pont Python <-> Binaire C
│
├── tests/
│   ├── test_valide.sgn      # Fichier sans erreurs (3 niveaux, 6 étudiants)
│   ├── test_erreur_lex.sgn  # Erreurs lexicales (4 erreurs)
│   ├── test_erreur_syn.sgn  # Erreurs syntaxiques (4 erreurs)
│   └── test_erreur_sem.sgn  # Erreurs sémantiques (5 erreurs)
│
├── rapport/
│   ├── rapport.pdf
│   └── rapport.tex
│
└── README.md
```

---



## Compilation

```bash
cd src/
make
```

Le `make` exécute automatiquement les étapes suivantes :

```
1. bison -d parser.y       →  parser.tab.c + parser.tab.h
2. flex lexer.l            →  lex.yy.c
3. gcc -c lex.yy.c         →  lex.yy.o
4. gcc -c parser.tab.c     →  parser.tab.o
5. gcc -c symboles.c       →  symboles.o
6. gcc -c ast.c            →  ast.o
7. gcc -c main.c           →  main.o
8. gcc ... -o sgn -lm      →  binaire final
```

---

## Utilisation du binaire C

```bash
# Analyser un fichier .sgn
./sgn fichier.sgn

# Lire depuis stdin
./sgn < fichier.sgn

# Rediriger la sortie JSON
./sgn fichier.sgn > resultats.json

# Afficher erreurs séparément
./sgn fichier.sgn 2>erreurs.txt
```

**Code de retour :**
- `0` — analyse réussie, aucune erreur
- `1` — erreurs lexicales, syntaxiques ou sémantiques détectées

---

## Format de sortie JSON

Le binaire écrit sur **stdout** un objet JSON structuré :

```json
{
  "annee": "2025-2026",
  "niveaux": [
    {
      "niveau": "L1",
      "etudiants": [
        {
          "matricule": "L1-2025-001",
          "nom": "DIALLO Mamadou",
          "prenom": "Mamadou",
          "semestres": [
            {
              "id": "S1",
              "modules": [
                {"nom": "Algorithmique", "coef": 3, "note": 14.50}
              ],
              "moyenne": 14.50
            }
          ],
          "moyenne_annuelle": 14.50,
          "mention": "Assez Bien",
          "decision": "Admis",
          "rang": 1
        }
      ]
    }
  ],
  "nb_erreurs": 0
}
```

Les **erreurs** sont écrites sur **stderr** :

```
[ERREUR LEXICALE]   Ligne 12 : Caractere inattendu : '@'
[ERREUR SYNTAXIQUE] Ligne 18 : syntax error
[ERREUR SEMANTIQUE] Ligne 23 : Note 25.00 hors intervalle [0.0, 20.0]
```

---

## Lancement de l'interface Python

```bash
cd gui/
python3 app.py
```

L'interface permet de :
- Charger et éditer un fichier `.sgn`
- Lancer l'analyse (appel au binaire `sgn` via `subprocess`)
- Afficher les résultats dans un tableau
- Visualiser les erreurs avec numéro de ligne
- Exporter les résultats en `.csv` ou `.txt`

---

## Tests

### Lancer tous les tests depuis `src/`

```bash
make test        # test_valide.sgn     → JSON correct, 0 erreur
make test_err    # test_erreur_sem.sgn → 5 erreurs sémantiques
make test_lex    # test_erreur_lex.sgn → erreurs lexicales
```

### Description des fichiers de test

| Fichier               | Contenu                  | Erreurs attendues        |
|-----------------------|--------------------------|--------------------------|
| `test_valide.sgn`     | 3 niveaux, 6 étudiants, toutes les mentions | Aucune                   |
| `test_erreur_lex.sgn` | Caractères invalides `@`, `#`, `$`, guillemet non fermé | 4 erreurs lexicales |
| `test_erreur_syn.sgn` | PRENOM manquant, accolade oubliée, NOTE absent, MATRICULE manquant | 4 erreurs syntaxiques |
| `test_erreur_sem.sgn` | Coef=0, note=25.0, note=-3.0, S4 dans L1, doublon matricule | 5 erreurs sémantiques |

### Test manuel rapide

```bash
cd src/
./sgn ../tests/test_valide.sgn | python3 -m json.tool
```

---

## Intégration Python ↔ C

La communication se fait uniquement via `subprocess` :

```python
import subprocess, json

result = subprocess.run(
    ["./src/sgn", "fichier.sgn"],
    capture_output=True,
    text=True
)

# Résultats JSON
data   = json.loads(result.stdout)

# Erreurs (lexicales/syntaxiques/sémantiques)
errors = result.stderr

# Code de retour
ok = (result.returncode == 0)
```

---

## Règles de calcul

**Moyenne pondérée d'un semestre :**

$$\bar{M}_s = \frac{\sum_{i=1}^{n} c_i \times n_i}{\sum_{i=1}^{n} c_i}$$

**Moyenne annuelle :**

$$\bar{M}_a = \frac{1}{S} \sum_{s=1}^{S} \bar{M}_s$$

**Décision de passage :**

| Moyenne annuelle   | Décision | Mention       |
|--------------------|----------|---------------|
| ≥ 16.0             | Admis    | Très Bien     |
| 14.0 ≤ M < 16.0    | Admis    | Bien          |
| 12.0 ≤ M < 14.0    | Admis    | Assez Bien    |
| 10.0 ≤ M < 12.0    | Admis    | Passable      |
| < 10.0             | Ajourné  | —             |

---

## Vérifications sémantiques

Le compilateur effectue automatiquement 4 vérifications :

1. **Note dans [0.0, 20.0]** — toute note hors intervalle est signalée
2. **Coefficient ≥ 1** — un coefficient nul ou négatif est invalide
3. **Cohérence semestre/niveau** — L1 → S1,S2 | L2 → S3,S4 | L3 → S5,S6
4. **Unicité du matricule** — pas de doublon dans un même niveau

---

## Nettoyage

```bash
cd src/
make clean
```

Supprime : `lex.yy.c`, `parser.tab.c`, `parser.tab.h`, les fichiers `.o` et le binaire `sgn`.

---

## Auteurs

- **[Macky Mamadou WONE]** — `src/` : lexer, parser, AST, table de symboles
- **[Modou Mbaye]** — `gui/` : interface Python
- **[Mouhammad Naasiri Diin DEME]** — `rapport/` : rapport technique

---

## Références

- Flex & Bison — John Levine, O'Reilly, 2009
- Compilers: Principles, Techniques, and Tools — Aho, Lam, Sethi, Ullman
- [Documentation Flex](https://github.com/westes/flex)
- [Documentation Bison](https://www.gnu.org/software/bison/manual/)
- [Python subprocess](https://docs.python.org/3/library/subprocess.html)