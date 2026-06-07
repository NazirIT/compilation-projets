/*
 * parser.y - Analyseur Syntaxique et Semantique Bison
 * Projet  : Systeme de Gestion des Notes (SGN)
 * Module  : Compilation - Master 1 Informatique
 * Auteur  : [NOM1] [NOM2]
 * Date    : 2025-2026
 *
 * Compilation : bison -d parser.y   -> parser.tab.c + parser.tab.h
 * Puis         : flex lexer.l       -> lex.yy.c
 * Puis         : make               -> binaire sgn
 */

/* ========================================================
   SECTION 1 : Declarations C
   ======================================================== */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "symboles.h"
#include "ast.h"

/* --------------------------------------------------------
   Variables globales
   -------------------------------------------------------- */
Programme    g_programme;              /* donnees parsees       */
TableSymboles g_table;                 /* table de symboles     */
ASTNode      *g_ast_racine = NULL;     /* racine de l'AST       */
int           g_erreurs    = 0;        /* compteur d'erreurs    */

/* Pointeurs de contexte courant durant le parsing */
Niveau   *g_niveau_courant   = NULL;
Etudiant *g_etudiant_courant = NULL;
Semestre *g_semestre_courant = NULL;

/* Noeuds AST courants */
ASTNode  *g_ast_niveau_courant   = NULL;
ASTNode  *g_ast_etudiant_courant = NULL;
ASTNode  *g_ast_semestre_courant = NULL;

/* --------------------------------------------------------
   Prototypes
   -------------------------------------------------------- */
void yyerror(const char *msg);
int  yylex(void);
extern int yylineno;
void afficher_json_global(void);
%}

/* ========================================================
   SECTION 2 : Declarations Bison
   ======================================================== */
%union {
    double  reel;
    int     entier;
    char   *chaine;
}

%token ANNEE NIVEAU_KW ETUDIANT MATRICULE NOM_TOK PRENOM_TOK
%token SEMESTRE MODULE_KW COEF NOTE
%token LBRACE RBRACE COLON
%token <chaine> STRING
%token <reel>   REEL
%token <entier> ENTIER
%token L1 L2 L3
%token S1 S2 S3 S4 S5 S6
%token ERREUR_LEX

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
            strncpy(g_programme.annee, $2,
                    sizeof(g_programme.annee) - 1);
            /* Mettre a jour la valeur dans le noeud AST racine */
            if (g_ast_racine)
                g_ast_racine->valeur.chaine = strdup($2);
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
            /* --- Donnees --- */
            int idx = g_programme.nb_niveaux++;
            g_niveau_courant = &g_programme.niveaux[idx];
            strncpy(g_niveau_courant->id, $2,
                    sizeof(g_niveau_courant->id) - 1);
            g_niveau_courant->nb_etudiants = 0;

            /* --- AST --- */
            g_ast_niveau_courant =
                ast_creer_noeud(NODE_NIVEAU, $2, yylineno);
            if (g_ast_racine)
                ast_ajouter_enfant(g_ast_racine,
                                   g_ast_niveau_courant);
            free($2);
        }
      liste_etudiants RBRACE
        {
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
            /* --- Donnees --- */
            int idx = g_niveau_courant->nb_etudiants++;
            g_etudiant_courant =
                &g_niveau_courant->etudiants[idx];
            memset(g_etudiant_courant, 0, sizeof(Etudiant));

            /* --- AST --- */
            g_ast_etudiant_courant =
                ast_creer_noeud(NODE_ETUDIANT, NULL, yylineno);
            if (g_ast_niveau_courant)
                ast_ajouter_enfant(g_ast_niveau_courant,
                                   g_ast_etudiant_courant);
        }
      champs_etudiant liste_semestres RBRACE
        {
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
            /* --- Verification doublon via table de symboles --- */
            if (symb_inserer(&g_table, $3,
                             g_niveau_courant->id,
                             yylineno) == -1) {
                g_erreurs++;
            }

            /* --- Donnees --- */
            strncpy(g_etudiant_courant->matricule, $3,
                    sizeof(g_etudiant_courant->matricule) - 1);
            strncpy(g_etudiant_courant->nom, $6,
                    sizeof(g_etudiant_courant->nom) - 1);
            strncpy(g_etudiant_courant->prenom, $9,
                    sizeof(g_etudiant_courant->prenom) - 1);

            /* --- AST : noeuds feuilles --- */
            if (g_ast_etudiant_courant) {
                ast_ajouter_enfant(g_ast_etudiant_courant,
                    ast_creer_noeud(NODE_MATRICULE, $3, yylineno));
                ast_ajouter_enfant(g_ast_etudiant_courant,
                    ast_creer_noeud(NODE_NOM,       $6, yylineno));
                ast_ajouter_enfant(g_ast_etudiant_courant,
                    ast_creer_noeud(NODE_PRENOM,    $9, yylineno));
            }
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
            /* --- Verification coherence semestre/niveau --- */
            verifier_semestre_niveau($2, g_niveau_courant->id);

            /* --- Donnees --- */
            int idx = g_etudiant_courant->nb_semestres++;
            g_semestre_courant =
                &g_etudiant_courant->semestres[idx];
            strncpy(g_semestre_courant->id, $2,
                    sizeof(g_semestre_courant->id) - 1);
            g_semestre_courant->nb_modules = 0;

            /* --- AST --- */
            g_ast_semestre_courant =
                ast_creer_noeud(NODE_SEMESTRE, $2, yylineno);
            if (g_ast_etudiant_courant)
                ast_ajouter_enfant(g_ast_etudiant_courant,
                                   g_ast_semestre_courant);
            free($2);
        }
      liste_modules RBRACE
        {
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
            /* --- Verifications semantiques --- */
            verifier_note($6, yylineno);
            verifier_coef($4, yylineno);

            /* --- Donnees --- */
            int idx = g_semestre_courant->nb_modules++;
            strncpy(g_semestre_courant->modules[idx].nom, $2,
                    sizeof(g_semestre_courant->modules[idx].nom) - 1);
            g_semestre_courant->modules[idx].coef = $4;
            g_semestre_courant->modules[idx].note = $6;

            /* --- AST : noeud feuille MODULE --- */
            if (g_ast_semestre_courant)
                ast_ajouter_enfant(g_ast_semestre_courant,
                    ast_creer_module($2, $4, $6, yylineno));
            free($2);
        }
    ;

%%

/* ========================================================
   SECTION 4 : Fonctions C
   ======================================================== */

/* --------------------------------------------------------
   yyerror : appelee par Bison sur erreur syntaxique
   -------------------------------------------------------- */
void yyerror(const char *msg) {
    fprintf(stderr, "[ERREUR SYNTAXIQUE] Ligne %d : %s\n",
            yylineno, msg);
    g_erreurs++;
}

/* --------------------------------------------------------
   verifier_note : note dans [0.0, 20.0]
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
   verifier_coef : coefficient >= 1
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
   verifier_semestre_niveau : coherence L1->S1,S2 etc.
   -------------------------------------------------------- */
void verifier_semestre_niveau(const char *id_sem,
                               const char *id_niv) {
    int ok = 0;
    if      (strcmp(id_niv, "L1") == 0)
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
   calculer_moyenne_semestre
   M = sum(coef_i * note_i) / sum(coef_i)
   -------------------------------------------------------- */
double calculer_moyenne_semestre(Semestre *s) {
    double sum_poids = 0.0, sum_coefs = 0.0;
    int i;
    if (s->nb_modules == 0) return 0.0;
    for (i = 0; i < s->nb_modules; i++) {
        sum_poids += s->modules[i].coef * s->modules[i].note;
        sum_coefs += s->modules[i].coef;
    }
    return (sum_coefs == 0.0) ? 0.0 : sum_poids / sum_coefs;
}

/* --------------------------------------------------------
   calculer_moyenne_annuelle
   Moyenne arithmetique des moyennes semestrielles
   -------------------------------------------------------- */
double calculer_moyenne_annuelle(Etudiant *e) {
    double total = 0.0;
    int i;
    if (e->nb_semestres == 0) return 0.0;
    for (i = 0; i < e->nb_semestres; i++)
        total += e->semestres[i].moyenne;
    return total / e->nb_semestres;
}

/* --------------------------------------------------------
   calculer_mention
   -------------------------------------------------------- */
void calculer_mention(Etudiant *e) {
    double m = e->moyenne_annuelle;
    if      (m >= 16.0) { strcpy(e->mention,"Tres Bien");  strcpy(e->decision,"Admis");   }
    else if (m >= 14.0) { strcpy(e->mention,"Bien");       strcpy(e->decision,"Admis");   }
    else if (m >= 12.0) { strcpy(e->mention,"Assez Bien"); strcpy(e->decision,"Admis");   }
    else if (m >= 10.0) { strcpy(e->mention,"Passable");   strcpy(e->decision,"Admis");   }
    else                { strcpy(e->mention,"");            strcpy(e->decision,"Ajourne"); }
}

/* --------------------------------------------------------
   calculer_rangs
   -------------------------------------------------------- */
void calculer_rangs(Niveau *niv) {
    int i, j, n = niv->nb_etudiants;
    for (i = 0; i < n; i++) niv->etudiants[i].rang = 1;
    for (i = 0; i < n; i++)
        for (j = 0; j < n; j++)
            if (i != j &&
                niv->etudiants[j].moyenne_annuelle >
                niv->etudiants[i].moyenne_annuelle)
                niv->etudiants[i].rang++;
}

/* --------------------------------------------------------
   json_string_safe : echappe les caracteres speciaux JSON
   -------------------------------------------------------- */
void json_string_safe(const char *s) {
    if (!s) return;
    while (*s) {
        switch (*s) {
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
   afficher_json : sortie JSON sur stdout pour Python
   -------------------------------------------------------- */
void afficher_json(Programme *p) {
    int ni, ne, ns, nm;
    printf("{\n");
    printf("  \"annee\": \""); json_string_safe(p->annee); printf("\",\n");
    printf("  \"niveaux\": [\n");

    for (ni = 0; ni < p->nb_niveaux; ni++) {
        Niveau *niv = &p->niveaux[ni];
        printf("    {\n");
        printf("      \"niveau\": \"%s\",\n", niv->id);
        printf("      \"etudiants\": [\n");

        for (ne = 0; ne < niv->nb_etudiants; ne++) {
            Etudiant *e = &niv->etudiants[ne];
            printf("        {\n");
            printf("          \"matricule\": \""); json_string_safe(e->matricule); printf("\",\n");
            printf("          \"nom\": \"");       json_string_safe(e->nom);       printf("\",\n");
            printf("          \"prenom\": \"");    json_string_safe(e->prenom);    printf("\",\n");
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
                    printf("\", \"coef\": %d, \"note\": %.2f}", m->coef, m->note);
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
            printf("          \"moyenne_annuelle\": %.2f,\n", e->moyenne_annuelle);
            printf("          \"mention\": \"");  json_string_safe(e->mention);  printf("\",\n");
            printf("          \"decision\": \""); json_string_safe(e->decision); printf("\",\n");
            printf("          \"rang\": %d\n", e->rang);
            printf("        }");
            if (ne < niv->nb_etudiants - 1) printf(",");
            printf("\n");
        }
        printf("      ]\n    }");
        if (ni < p->nb_niveaux - 1) printf(",");
        printf("\n");
    }

    printf("  ],\n");
    printf("  \"erreurs\": [],\n");
    printf("  \"nb_erreurs\": %d\n", g_erreurs);
    printf("}\n");
}

/* --------------------------------------------------------
   afficher_json_global : appelee par main.c
   -------------------------------------------------------- */
void afficher_json_global(void) {
    /* Optionnel : afficher l'AST sur stderr pour le debug */
    /* ast_afficher(g_ast_racine, 0); */
    afficher_json(&g_programme);
}
