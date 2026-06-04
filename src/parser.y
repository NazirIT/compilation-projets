/*
 * parser.y - Analyseur Syntaxique et Semantique Bison
 * Projet  : Systeme de Gestion des Notes (SGN)
 * Module  : Compilation - Master 1 Informatique
 * Auteur  : [NOM1] [NOM2]
 * Date    : 2025-2026
 *
 * Compilation : bison -d parser.y   (genere parser.tab.c et parser.tab.h)
 * Puis         : flex lexer.l       (genere lex.yy.c)
 * Puis         : gcc lex.yy.c parser.tab.c main.c -o sgn -lm
 */

/* ========================================================
   SECTION 1 : Declarations C
   ======================================================== */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

/* --------------------------------------------------------
   Constantes
   -------------------------------------------------------- */
#define MAX_MODULES    50
#define MAX_SEMESTRES  6
#define MAX_ETUDIANTS  200
#define MAX_NIVEAUX    3
#define NOTE_MIN       0.0
#define NOTE_MAX       20.0
#define COEF_MIN       1

/* --------------------------------------------------------
   Structures de donnees
   -------------------------------------------------------- */

/* Un module : nom, coefficient, note */
typedef struct {
    char  *nom;
    int    coef;
    double note;
} Module;

/* Un semestre : identifiant (ex: "S1"), liste de modules */
typedef struct {
    char    id[4];         /* "S1" .. "S6" */
    Module  modules[MAX_MODULES];
    int     nb_modules;
    double  moyenne;       /* calculee apres parsing */
} Semestre;

/* Un etudiant */
typedef struct {
    char      matricule[64];
    char      nom[128];
    char      prenom[64];
    Semestre  semestres[MAX_SEMESTRES];
    int       nb_semestres;
    double    moyenne_annuelle; /* calculee apres parsing */
    char      mention[32];
    char      decision[16];
    int       rang;             /* calcule apres tous les etudiants */
} Etudiant;

/* Un niveau (L1, L2, L3) */
typedef struct {
    char      id[4];        /* "L1", "L2", "L3" */
    Etudiant  etudiants[MAX_ETUDIANTS];
    int       nb_etudiants;
} Niveau;

/* Le programme entier */
typedef struct {
    char   annee[16];
    Niveau niveaux[MAX_NIVEAUX];
    int    nb_niveaux;
} Programme;

/* --------------------------------------------------------
   Variables globales
   -------------------------------------------------------- */
Programme g_programme;        /* structure principale */
int       g_erreurs = 0;      /* compteur d'erreurs semantiques */

/* Pointeurs de travail (contexte courant durant le parsing) */
Niveau   *g_niveau_courant   = NULL;
Etudiant *g_etudiant_courant = NULL;
Semestre *g_semestre_courant = NULL;

/* --------------------------------------------------------
   Prototypes des fonctions
   -------------------------------------------------------- */
void   yyerror(const char *msg);
int    yylex(void);
extern int yylineno;

/* Fonctions semantiques */
void   verifier_note(double note, int ligne);
void   verifier_coef(int coef, int ligne);
void   verifier_doublon_matricule(const char *matricule, Niveau *niv);
void   verifier_semestre_niveau(const char *id_sem, const char *id_niv);
double calculer_moyenne_semestre(Semestre *s);
double calculer_moyenne_annuelle(Etudiant *e);
void   calculer_mention(Etudiant *e);
void   calculer_rangs(Niveau *niv);

/* Fonctions de sortie JSON */
void   afficher_json(Programme *p);
void   json_string_safe(const char *s);

%}

/* ========================================================
   SECTION 2 : Declarations Bison
   ======================================================== */

/* Union des types de valeurs semantiques.
   Chaque symbole grammatical peut avoir un type. */
%union {
    double  reel;
    int     entier;
    char   *chaine;
}

/* Declaration des tokens avec leurs types */
%token ANNEE NIVEAU_KW ETUDIANT MATRICULE NOM_TOK PRENOM_TOK
%token SEMESTRE MODULE_KW COEF NOTE
%token LBRACE RBRACE COLON
%token <chaine> STRING
%token <reel>   REEL
%token <entier> ENTIER
%token L1 L2 L3
%token S1 S2 S3 S4 S5 S6
%token ERREUR_LEX

/* Types des symboles non-terminaux */
%type <chaine> id_niveau id_semestre

/* ========================================================
   SECTION 3 : Regles de grammaire
   ======================================================== */
%%

/* --------------------------------------------------------
   programme ::= ANNEE STRING liste_niveaux
   -------------------------------------------------------- */
programme
    : ANNEE STRING liste_niveaux
        {
            strncpy(g_programme.annee, $2, sizeof(g_programme.annee)-1);
            free($2);
        }
    ;

/* --------------------------------------------------------
   liste_niveaux ::= niveau | liste_niveaux niveau
   -------------------------------------------------------- */
liste_niveaux
    : niveau
    | liste_niveaux niveau
    ;

/* --------------------------------------------------------
   niveau ::= NIVEAU id_niveau '{' liste_etudiants '}'
   -------------------------------------------------------- */
niveau
    : NIVEAU_KW id_niveau LBRACE
        {
            /* Creer un nouveau niveau dans le programme */
            int idx = g_programme.nb_niveaux;
            g_programme.nb_niveaux++;
            g_niveau_courant = &g_programme.niveaux[idx];
            strncpy(g_niveau_courant->id, $2, sizeof(g_niveau_courant->id)-1);
            g_niveau_courant->nb_etudiants = 0;
            free($2);
        }
      liste_etudiants RBRACE
        {
            /* Calcul des rangs dans ce niveau */
            calculer_rangs(g_niveau_courant);
        }
    ;

/* --------------------------------------------------------
   id_niveau ::= L1 | L2 | L3
   -------------------------------------------------------- */
id_niveau
    : L1  { $$ = strdup("L1"); }
    | L2  { $$ = strdup("L2"); }
    | L3  { $$ = strdup("L3"); }
    ;

/* --------------------------------------------------------
   liste_etudiants ::= etudiant | liste_etudiants etudiant
   -------------------------------------------------------- */
liste_etudiants
    : etudiant
    | liste_etudiants etudiant
    ;

/* --------------------------------------------------------
   etudiant ::= ETUDIANT '{' champs_etudiant liste_semestres '}'
   -------------------------------------------------------- */
etudiant
    : ETUDIANT LBRACE
        {
            /* Creer un nouvel etudiant dans le niveau courant */
            int idx = g_niveau_courant->nb_etudiants;
            g_niveau_courant->nb_etudiants++;
            g_etudiant_courant = &g_niveau_courant->etudiants[idx];
            memset(g_etudiant_courant, 0, sizeof(Etudiant));
        }
      champs_etudiant liste_semestres RBRACE
        {
            /* Calculer la moyenne annuelle et la mention */
            g_etudiant_courant->moyenne_annuelle =
                calculer_moyenne_annuelle(g_etudiant_courant);
            calculer_mention(g_etudiant_courant);
        }
    ;

/* --------------------------------------------------------
   champs_etudiant ::= MATRICULE ':' STRING
                       NOM ':' STRING
                       PRENOM ':' STRING
   -------------------------------------------------------- */
champs_etudiant
    : MATRICULE COLON STRING
      NOM_TOK   COLON STRING
      PRENOM_TOK COLON STRING
        {
            /* Verification doublon matricule */
            verifier_doublon_matricule($3, g_niveau_courant);

            strncpy(g_etudiant_courant->matricule, $3,
                    sizeof(g_etudiant_courant->matricule)-1);
            strncpy(g_etudiant_courant->nom, $6,
                    sizeof(g_etudiant_courant->nom)-1);
            strncpy(g_etudiant_courant->prenom, $9,
                    sizeof(g_etudiant_courant->prenom)-1);
            free($3); free($6); free($9);
        }
    ;

/* --------------------------------------------------------
   liste_semestres ::= semestre | liste_semestres semestre
   -------------------------------------------------------- */
liste_semestres
    : semestre
    | liste_semestres semestre
    ;

/* --------------------------------------------------------
   semestre ::= SEMESTRE id_semestre '{' liste_modules '}'
   -------------------------------------------------------- */
semestre
    : SEMESTRE id_semestre LBRACE
        {
            /* Verifier coherence semestre/niveau */
            verifier_semestre_niveau($2, g_niveau_courant->id);

            int idx = g_etudiant_courant->nb_semestres;
            g_etudiant_courant->nb_semestres++;
            g_semestre_co%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yyparse();
extern FILE *yyin;
void yyerror(const char *s);

int erreur_syntaxique = 0;
int nb_ligne = 1;

/* Compteurs pour gérer les virgules dans JSON */
int premier_etudiant = 1;
int premier_semestre = 1;
int premier_module = 1;
int premier_niveau = 1;
%}

/* Déclaration des tokens */
%token TOKEN_ANNEE 258
%token TOKEN_NIVEAU 259
%token TOKEN_ETUDIANT 260
%token TOKEN_MATRICULE 261
%token TOKEN_NOM 262
%token TOKEN_PRENOM 263
%token TOKEN_SEMESTRE 264
%token TOKEN_MODULE 265
%token TOKEN_COEF 266
%token TOKEN_NOTE 267
%token TOKEN_L1 268
%token TOKEN_L2 269
%token TOKEN_L3 270
%token TOKEN_S1 271
%token TOKEN_S2 272
%token TOKEN_S3 273
%token TOKEN_S4 274
%token TOKEN_S5 275
%token TOKEN_S6 276
%token <entier> TOKEN_ENTIER 277
%token <reel> TOKEN_REEL 278
%token <chaine> TOKEN_STRING 279
%token TOKEN_LBRACE 280
%token TOKEN_RBRACE 281
%token TOKEN_COLON 282
%token TOKEN_ERREUR 283

%union {
    int entier;
    double reel;
    char *chaine;
}

%type <entier> id_niveau id_semestre

%start programme

%%

/* Règle principale */
programme:
    TOKEN_ANNEE TOKEN_STRING
    {
        printf("{\n");
        printf("  \"annee\": %s,\n", $2);
        printf("  \"niveaux\": [\n");
    }
    liste_niveaux
    {
        printf("  ]\n");
        printf("}\n");
    }
    ;

liste_niveaux:
    niveau
    | liste_niveaux niveau
    ;

niveau:
    TOKEN_NIVEAU id_niveau TOKEN_LBRACE liste_etudiants TOKEN_RBRACE
    {
        printf("      ]\n");
        printf("    }\n");
    }
    ;

id_niveau:
    TOKEN_L1 { 
        if (!premier_niveau) printf(",\n");
        premier_niveau = 0;
        printf("    {\n");
        printf("      \"niveau\": \"L1\",\n");
        printf("      \"etudiants\": [\n");
        premier_etudiant = 1;
    }
    | TOKEN_L2 {
        if (!premier_niveau) printf(",\n");
        premier_niveau = 0;
        printf("    {\n");
        printf("      \"niveau\": \"L2\",\n");
        printf("      \"etudiants\": [\n");
        premier_etudiant = 1;
    }
    | TOKEN_L3 {
        if (!premier_niveau) printf(",\n");
        premier_niveau = 0;
        printf("    {\n");
        printf("      \"niveau\": \"L3\",\n");
        printf("      \"etudiants\": [\n");
        premier_etudiant = 1;
    }
    ;

liste_etudiants:
    etudiant
    | liste_etudiants etudiant
    ;

etudiant:
    TOKEN_ETUDIANT TOKEN_LBRACE champs_etudiant liste_semestres TOKEN_RBRACE
    {
        printf("        ]\n");
        printf("      }\n");
    }
    ;

champs_etudiant:
    TOKEN_MATRICULE TOKEN_COLON TOKEN_STRING
    TOKEN_NOM TOKEN_COLON TOKEN_STRING
    TOKEN_PRENOM TOKEN_COLON TOKEN_STRING
    {
        if (!premier_etudiant) printf(",\n");
        premier_etudiant = 0;
        printf("      {\n");
        printf("        \"matricule\": %s,\n", $3);
        printf("        \"nom\": %s,\n", $6);
        printf("        \"prenom\": %s,\n", $9);
        printf("        \"semestres\": [\n");
        premier_semestre = 1;
    }
    ;

liste_semestres:
    semestre
    | liste_semestres semestre
    ;

semestre:
    TOKEN_SEMESTRE id_semestre TOKEN_LBRACE liste_modules TOKEN_RBRACE
    {
        printf("          ]\n");
        printf("        }\n");
    }
    ;

id_semestre:
    TOKEN_S1 { 
        if (!premier_semestre) printf(",\n");
        premier_semestre = 0;
        printf("          {\n");
        printf("            \"semestre\": \"S1\",\n");
        printf("            \"modules\": [\n");
        premier_module = 1;
        $$ = 1;
    }
    | TOKEN_S2 {
        if (!premier_semestre) printf(",\n");
        premier_semestre = 0;
        printf("          {\n");
        printf("            \"semestre\": \"S2\",\n");
        printf("            \"modules\": [\n");
        premier_module = 1;
        $$ = 2;
    }
    | TOKEN_S3 {
        if (!premier_semestre) printf(",\n");
        premier_semestre = 0;
        printf("          {\n");
        printf("            \"semestre\": \"S3\",\n");
        printf("            \"modules\": [\n");
        premier_module = 1;
        $$ = 3;
    }
    | TOKEN_S4 {
        if (!premier_semestre) printf(",\n");
        premier_semestre = 0;
        printf("          {\n");
        printf("            \"semestre\": \"S4\",\n");
        printf("            \"modules\": [\n");
        premier_module = 1;
        $$ = 4;
    }
    | TOKEN_S5 {
        if (!premier_semestre) printf(",\n");
        premier_semestre = 0;
        printf("          {\n");
        printf("            \"semestre\": \"S5\",\n");
        printf("            \"modules\": [\n");
        premier_module = 1;
        $$ = 5;
    }
    | TOKEN_S6 {
        if (!premier_semestre) printf(",\n");
        premier_semestre = 0;
        printf("          {\n");
        printf("            \"semestre\": \"S6\",\n");
        printf("            \"modules\": [\n");
        premier_module = 1;
        $$ = 6;
    }
    ;

liste_modules:
    module
    | liste_modules module
    ;

module:
    TOKEN_MODULE TOKEN_STRING TOKEN_COEF TOKEN_ENTIER TOKEN_NOTE TOKEN_REEL
    {
        if (!premier_module) printf(",\n");
        premier_module = 0;
        printf("              {\n");
        printf("                \"module\": %s,\n", $2);
        printf("                \"coefficient\": %d,\n", $4);
        printf("                \"note\": %.2f\n", $6);
        printf("              }\n");
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "ERREUR SYNTAXIQUE: %s\n", s);
    erreur_syntaxique = 1;
}

int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Impossible d'ouvrir le fichier %s\n", argv[1]);
            return 1;
        }
    }
    
    yyparse();
    
    if (!erreur_syntaxique) {
        printf("\n=== Analyse syntaxique réussie ===\n");
    } else {
        printf("\n=== Analyse syntaxique échouée ===\n");
    }
    
    return 0;
}
urant = &g_etudiant_courant->semestres[idx];
            strncpy(g_semestre_courant->id, $2,
                    sizeof(g_semestre_courant->id)-1);
            g_semestre_courant->nb_modules = 0;
            free($2);
        }
      liste_modules RBRACE
        {
            /* Calculer la moyenne de ce semestre */
            g_semestre_courant->moyenne =
                calculer_moyenne_semestre(g_semestre_courant);
        }
    ;

/* --------------------------------------------------------
   id_semestre ::= S1 | S2 | S3 | S4 | S5 | S6
   -------------------------------------------------------- */
id_semestre
    : S1  { $$ = strdup("S1"); }
    | S2  { $$ = strdup("S2"); }
    | S3  { $$ = strdup("S3"); }
    | S4  { $$ = strdup("S4"); }
    | S5  { $$ = strdup("S5"); }
    | S6  { $$ = strdup("S6"); }
    ;

/* --------------------------------------------------------
   liste_modules ::= module | liste_modules module
   -------------------------------------------------------- */
liste_modules
    : module
    | liste_modules module
    ;

/* --------------------------------------------------------
   module ::= MODULE STRING COEF ENTIER NOTE REEL
   -------------------------------------------------------- */
module
    : MODULE_KW STRING COEF ENTIER NOTE REEL
        {
            /* Verifications semantiques */
            verifier_note($6, yylineno);
            verifier_coef($4, yylineno);

            /* Ajouter le module au semestre courant */
            int idx = g_semestre_courant->nb_modules;
            g_semestre_courant->nb_modules++;
            g_semestre_courant->modules[idx].nom  = strdup($2);
            g_semestre_courant->modules[idx].coef = $4;
            g_semestre_courant->modules[idx].note = $6;
            free($2);
        }
    ;

%%

/* ========================================================
   SECTION 4 : Fonctions C
   ======================================================== */

/* --------------------------------------------------------
   yyerror : appelee par Bison en cas d'erreur syntaxique
   -------------------------------------------------------- */
void yyerror(const char *msg) {
    fprintf(stderr, "[ERREUR SYNTAXIQUE] Ligne %d : %s\n",
            yylineno, msg);
    g_erreurs++;
}

/* --------------------------------------------------------
   Verification semantique : note dans [0.0, 20.0]
   -------------------------------------------------------- */
void verifier_note(double note, int ligne) {
    if (note < NOTE_MIN || note > NOTE_MAX) {
        fprintf(stderr,
            "[ERREUR SEMANTIQUE] Ligne %d : "
            "Note %.2f hors intervalle [0.0, 20.0]\n",
            ligne, note);
        g_erreurs++;
    }
}

/* --------------------------------------------------------
   Verification semantique : coefficient >= 1
   -------------------------------------------------------- */
void verifier_coef(int coef, int ligne) {
    if (coef < COEF_MIN) {
        fprintf(stderr,
            "[ERREUR SEMANTIQUE] Ligne %d : "
            "Coefficient %d invalide (doit etre >= 1)\n",
            ligne, coef);
        g_erreurs++;
    }
}

/* --------------------------------------------------------
   Verification semantique : pas de doublon de matricule
   dans un meme niveau
   -------------------------------------------------------- */
void verifier_doublon_matricule(const char *matricule, Niveau *niv) {
    int i;
    /* On parcourt les etudiants deja enregistres dans ce niveau
       (le courant n'est pas encore complete, on va jusqu'a nb-1) */
    for (i = 0; i < niv->nb_etudiants - 1; i++) {
        if (strcmp(niv->etudiants[i].matricule, matricule) == 0) {
            fprintf(stderr,
                "[ERREUR SEMANTIQUE] Ligne %d : "
                "Matricule '%s' en double dans le niveau %s\n",
                yylineno, matricule, niv->id);
            g_erreurs++;
            return;
        }
    }
}

/* --------------------------------------------------------
   Verification semantique : coherence semestre / niveau
   L1 -> S1, S2 | L2 -> S3, S4 | L3 -> S5, S6
   -------------------------------------------------------- */
void verifier_semestre_niveau(const char *id_sem, const char *id_niv) {
    int ok = 0;
    if (strcmp(id_niv, "L1") == 0)
        ok = (strcmp(id_sem,"S1")==0 || strcmp(id_sem,"S2")==0);
    else if (strcmp(id_niv, "L2") == 0)
        ok = (strcmp(id_sem,"S3")==0 || strcmp(id_sem,"S4")==0);
    else if (strcmp(id_niv, "L3") == 0)
        ok = (strcmp(id_sem,"S5")==0 || strcmp(id_sem,"S6")==0);

    if (!ok) {
        fprintf(stderr,
            "[ERREUR SEMANTIQUE] Ligne %d : "
            "Semestre '%s' incompatible avec le niveau '%s'\n",
            yylineno, id_sem, id_niv);
        g_erreurs++;
    }
}

/* --------------------------------------------------------
   Calcul de la moyenne ponderee d'un semestre
   M = sum(coef_i * note_i) / sum(coef_i)
   -------------------------------------------------------- */
double calculer_moyenne_semestre(Semestre *s) {
    double sum_poids = 0.0;
    double sum_coefs = 0.0;
    int i;
    if (s->nb_modules == 0) return 0.0;
    for (i = 0; i < s->nb_modules; i++) {
        sum_poids += s->modules[i].coef * s->modules[i].note;
        sum_coefs += s->modules[i].coef;
    }
    if (sum_coefs == 0.0) return 0.0;
    return sum_poids / sum_coefs;
}

/* --------------------------------------------------------
   Calcul de la moyenne annuelle : moyenne des moyennes
   semestrielles
   -------------------------------------------------------- */
double calculer_moyenne_annuelle(Etudiant *e) {
    double total = 0.0;
    int i;
    if (e->nb_semestres == 0) return 0.0;
    for (i = 0; i < e->nb_semestres; i++) {
        total += e->semestres[i].moyenne;
    }
    return total / e->nb_semestres;
}

/* --------------------------------------------------------
   Determine la mention et la decision selon la moyenne
   -------------------------------------------------------- */
void calculer_mention(Etudiant *e) {
    double m = e->moyenne_annuelle;
    if (m >= 16.0) {
        strcpy(e->mention,  "Tres Bien");
        strcpy(e->decision, "Admis");
    } else if (m >= 14.0) {
        strcpy(e->mention,  "Bien");
        strcpy(e->decision, "Admis");
    } else if (m >= 12.0) {
        strcpy(e->mention,  "Assez Bien");
        strcpy(e->decision, "Admis");
    } else if (m >= 10.0) {
        strcpy(e->mention,  "Passable");
        strcpy(e->decision, "Admis");
    } else {
        strcpy(e->mention,  "");
        strcpy(e->decision, "Ajourne");
    }
}

/* --------------------------------------------------------
   Calcul des rangs dans un niveau (tri par moyenne desc)
   Algorithme : tri a bulles sur les rangs (pas de tri en
   place pour ne pas reordonner le tableau)
   -------------------------------------------------------- */
void calculer_rangs(Niveau *niv) {
    int i, j;
    int n = niv->nb_etudiants;
    /* Initialiser tous les rangs a 1 */
    for (i = 0; i < n; i++) niv->etudiants[i].rang = 1;
    /* Pour chaque etudiant, compter combien ont une moyenne
       strictement superieure */
    for (i = 0; i < n; i++) {
        for (j = 0; j < n; j++) {
            if (i != j &&
                niv->etudiants[j].moyenne_annuelle >
                niv->etudiants[i].moyenne_annuelle) {
                niv->etudiants[i].rang++;
            }
        }
    }
}

/* --------------------------------------------------------
   Echapper les caracteres speciaux pour JSON
   -------------------------------------------------------- */
void json_string_safe(const char *s) {
    if (!s) { printf(""); return; }
    while (*s) {
        switch(*s) {
            case '"':  printf("\\\""); break;
            case '\\': printf("\\\\"); break;
            case '\n': printf("\\n");  break;
            case '\r': printf("\\r");  break;
            case '\t': printf("\\t");  break;
            default:   printf("%c", *s); break;
        }
        s++;
    }
}

/* --------------------------------------------------------
   Affichage du resultat au format JSON sur stdout
   C'est ce que lira l'interface Python via subprocess
   -------------------------------------------------------- */
void afficher_json(Programme *p) {
    int ni, ne, ns, nm;

    printf("{\n");
    printf("  \"annee\": \"");
    json_string_safe(p->annee);
    printf("\",\n");
    printf("  \"niveaux\": [\n");

    for (ni = 0; ni < p->nb_niveaux; ni++) {
        Niveau *niv = &p->niveaux[ni];
        printf("    {\n");
        printf("      \"niveau\": \"%s\",\n", niv->id);
        printf("      \"etudiants\": [\n");

        for (ne = 0; ne < niv->nb_etudiants; ne++) {
            Etudiant *e = &niv->etudiants[ne];
            printf("        {\n");
            printf("          \"matricule\": \"");
            json_string_safe(e->matricule);
            printf("\",\n");
            printf("          \"nom\": \"");
            json_string_safe(e->nom);
            printf("\",\n");
            printf("          \"prenom\": \"");
            json_string_safe(e->prenom);
            printf("\",\n");
            printf("          \"semestres\": [\n");

            for (ns = 0; ns < e->nb_semestres; ns++) {
                Semestre *s = &e->semestres[ns];
                printf("            {\n");
                printf("              \"id\": \"%s\",\n", s->id);
                printf("              \"modules\": [\n");

                for (nm = 0; nm < s->nb_modules; nm++) {
                    Module *m = &s->modules[nm];
                    printf("                {\"nom\": \"");
                    json_string_safe(m->nom);
                    printf("\", \"coef\": %d, \"note\": %.2f}",
                           m->coef, m->note);
                    if (nm < s->nb_modules - 1) printf(",");
                    printf("\n");
                }
                printf("              ],\n");
                printf("              \"moyenne\": %.2f\n", s->moyenne);
                printf("            }");
                if (ns < e->nb_semestres - 1) printf(",");
                printf("\n");
            }

            printf("          ],\n");
            printf("          \"moyenne_annuelle\": %.2f,\n",
                   e->moyenne_annuelle);
            printf("          \"mention\": \"");
            json_string_safe(e->mention);
            printf("\",\n");
            printf("          \"decision\": \"");
            json_string_safe(e->decision);
            printf("\",\n");
            printf("          \"rang\": %d\n", e->rang);
            printf("        }");
            if (ne < niv->nb_etudiants - 1) printf(",");
            printf("\n");
        }

        printf("      ]\n");
        printf("    }");
        if (ni < p->nb_niveaux - 1) printf(",");
        printf("\n");
    }

    printf("  ],\n");
    /* Nombre d'erreurs semantiques */
    printf("  \"nb_erreurs\": %d\n", g_erreurs);
    printf("}\n");
}

/* --------------------------------------------------------
   Fonction appelee par main.c apres le parsing
   -------------------------------------------------------- */
void afficher_json_global(void) {
    afficher_json(&g_programme);
}
