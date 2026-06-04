%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"  /* Important pour Bison */

extern int nb_ligne;

/* Pour stocker les valeurs des tokens */
extern YYSTYPE yylval;

%}

%option noyywrap

/* ===== DÉFINITIONS ===== */
ESPACE       [ \t]
CHIFFRE      [0-9]
LETTRE       [A-Za-z]

ENTIER       [0-9]+
REEL         [0-9]+\.[0-9]+
STRING       \"[^\"]*\"

%%

 /* Mots-clés */
"ANNEE"         { return TOKEN_ANNEE; }
"NIVEAU"        { return TOKEN_NIVEAU; }
"ETUDIANT"      { return TOKEN_ETUDIANT; }
"MATRICULE"     { return TOKEN_MATRICULE; }
"NOM"           { return TOKEN_NOM; }
"PRENOM"        { return TOKEN_PRENOM; }
"SEMESTRE"      { return TOKEN_SEMESTRE; }
"MODULE"        { return TOKEN_MODULE; }
"COEF"          { return TOKEN_COEF; }
"NOTE"          { return TOKEN_NOTE; }

 /* Niveaux */
"L1"            { return TOKEN_L1; }
"L2"            { return TOKEN_L2; }
"L3"            { return TOKEN_L3; }

 /* Semestres */
"S1"            { return TOKEN_S1; }
"S2"            { return TOKEN_S2; }
"S3"            { return TOKEN_S3; }
"S4"            { return TOKEN_S4; }
"S5"            { return TOKEN_S5; }
"S6"            { return TOKEN_S6; }

 /* Littéraux */
 {ENTIER}      { 
                 yylval.entier = atoi(yytext); 
                 return TOKEN_ENTIER; 
               }
 {REEL}        { 
                 yylval.reel = atof(yytext); 
                 return TOKEN_REEL; 
               }
 {STRING}      { 
                 yylval.chaine = strdup(yytext); 
                 return TOKEN_STRING; 
               }

 /* Ponctuation */
"{"           { return TOKEN_LBRACE; }
"}"           { return TOKEN_RBRACE; }
":"           { return TOKEN_COLON; }

 /* Commentaires */
"--".*        { /* on ignore */ }

 /* Espaces */
{ESPACE}+     { /* on ignore */ }
"\n"          { nb_ligne++; }

 /* Erreur */
.             { 
                fprintf(stderr, "ERREUR LEXICALE ligne %d : caractère inattendu '%c'\n", 
                       nb_ligne, yytext[0]);
                return TOKEN_ERREUR;
              }
