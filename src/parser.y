%{
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
