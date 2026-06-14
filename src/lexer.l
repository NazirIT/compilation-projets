

/* SECTION 1 : Declarations C et options Flex*/
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* En mode integration avec Bison, on inclut parser.tab.h
   En mode test seul, on definit les tokens manuellement */
#ifndef TEST_LEXER_ONLY
  #include "parser.tab.h"
#else
  enum {
    ANNEE=258, NIVEAU_KW, ETUDIANT, MATRICULE, NOM_TOK, PRENOM_TOK,
    SEMESTRE, MODULE_KW, COEF, NOTE,
    L1, L2, L3,
    S1, S2, S3, S4, S5, S6,
    REEL, ENTIER, STRING,
    LBRACE, RBRACE, COLON,
    ERREUR_LEX
  };
  union {
    double reel;
    int    entier;
    char  *chaine;
  } yylval;
#endif

void erreur_lexicale(const char *msg, int ligne);
%}

%option noyywrap
%option yylineno

CHIFFRE     [0-9]
BLANC       [ \t\r]+
REEL_DEF    {CHIFFRE}+("."{CHIFFRE}+)?
STRING_DEF  \"[^"\n]*\"

%%

"--"[^\n]*      { /* commentaire : ignorer */ }

"ANNEE"         { return ANNEE;      }
"NIVEAU"        { return NIVEAU_KW;     }
"ETUDIANT"      { return ETUDIANT;   }
"MATRICULE"     { return MATRICULE;  }
"NOM"           { return NOM_TOK;    }
"PRENOM"        { return PRENOM_TOK; }
"SEMESTRE"      { return SEMESTRE;   }
"MODULE"        { return MODULE_KW; }
"COEF"          { return COEF;       }
"NOTE"          { return NOTE;       }

"L1"            { return L1; }
"L2"            { return L2; }
"L3"            { return L3; }

"S1"            { return S1; }
"S2"            { return S2; }
"S3"            { return S3; }
"S4"            { return S4; }
"S5"            { return S5; }
"S6"            { return S6; }

{REEL_DEF}      {
                    if (strchr(yytext, '.') != NULL) {
                        yylval.reel = atof(yytext);
                        return REEL;
                    } else {
                        yylval.entier = atoi(yytext);
                        return ENTIER;
                    }
                }

{STRING_DEF}    {
                    int len = yyleng - 2;
                    yylval.chaine = (char*)malloc(len + 1);
                    if (!yylval.chaine) {
                        erreur_lexicale("Memoire insuffisante", yylineno);
                        exit(1);
                    }
                    strncpy(yylval.chaine, yytext + 1, len);
                    yylval.chaine[len] = '\0';
                    return STRING;
                }

"{"             { return LBRACE; }
"}"             { return RBRACE; }
":"             { return COLON;  }

{BLANC}         { /* ignorer espaces et tabulations */ }
"\n"            { /* saut de ligne gere par yylineno  */ }

.               {
                    char msg[64];
                    snprintf(msg, sizeof(msg), "Caractere inattendu : '%s'", yytext);
                    erreur_lexicale(msg, yylineno);
                    return ERREUR_LEX;
                }

%%

/*SECTION 3 : Fonctions C*/
  
void erreur_lexicale(const char *msg, int ligne) {
    fprintf(stderr, "[ERREUR LEXICALE] Ligne %d : %s\n", ligne, msg);
}

#ifdef TEST_LEXER_ONLY

const char *nom_token(int tok) {
    switch(tok) {
        case ANNEE:      return "ANNEE";
        case NIVEAU_KW:  return "NIVEAU";
        case ETUDIANT:   return "ETUDIANT";
        case MATRICULE:  return "MATRICULE";
        case NOM_TOK:    return "NOM";
        case PRENOM_TOK: return "PRENOM";
        case SEMESTRE:   return "SEMESTRE";
        case MODULE_KW:  return "MODULE";
        case COEF:       return "COEF";
        case NOTE:       return "NOTE";
        case L1:         return "L1";
        case L2:         return "L2";
        case L3:         return "L3";
        case S1:         return "S1";
        case S2:         return "S2";
        case S3:         return "S3";
        case S4:         return "S4";
        case S5:         return "S5";
        case S6:         return "S6";
        case REEL:       return "REEL";
        case ENTIER:     return "ENTIER";
        case STRING:     return "STRING";
        case LBRACE:     return "LBRACE {";
        case RBRACE:     return "RBRACE }";
        case COLON:      return "COLON  :";
        case ERREUR_LEX: return "ERREUR_LEXICALE";
        default:         return "INCONNU";
    }
}

int main(int argc, char *argv[]) {
    int tok;
    printf("=== Analyseur Lexical SGN - Mode Test ===\n");
    printf("%-6s  %-20s  %s\n", "Ligne", "Token", "Valeur");
    printf("--------------------------------------------------\n");

    while ((tok = yylex()) != 0) {
        printf("%-6d  %-20s  ", yylineno, nom_token(tok));
        switch(tok) {
            case REEL:
                printf("%.2f", yylval.reel);
                break;
            case ENTIER:
                printf("%d", yylval.entier);
                break;
            case STRING:
                printf("\"%s\"", yylval.chaine);
                free(yylval.chaine);
                break;
            default:
                printf("%s", yytext);
                break;
        }
        printf("\n");
    }
    printf("--------------------------------------------------\n");
    printf("Analyse lexicale terminee.\n");
    return 0;
}
#endif
