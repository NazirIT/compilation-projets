/*
 * main.c - Point d'entree du programme SGN
 * Projet  : Systeme de Gestion des Notes (SGN)
 * Module  : Compilation - Master 1 Informatique
 * Auteur  : [NOM1] [NOM2]
 * Date    : 2025-2026
 *
 * Usage : ./sgn fichier.sgn
 *         ./sgn < fichier.sgn
 */
#include <stdio.h>
#include <stdlib.h>
#include "symboles.h"
#include "ast.h"

/* Declares dans parser.tab.c */
extern int   yyparse(void);
extern FILE *yyin;
extern int   g_erreurs;
extern void  afficher_json_global(void);

/* Table de symboles et AST declares dans parser.y */
extern TableSymboles g_table;
extern ASTNode      *g_ast_racine;

int main(int argc, char *argv[]) {

    /* Initialiser la table de symboles */
    symb_initialiser(&g_table);

    /* Creer le noeud racine de l'AST */
    g_ast_racine = ast_creer_noeud(NODE_PROGRAMME, NULL, 0);

    /* Ouvrir le fichier source ou lire depuis stdin */
    if (argc >= 2) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr,
                "[ERREUR] Impossible d'ouvrir : %s\n", argv[1]);
            return 1;
        }
    } else {
        yyin = stdin;
    }

    /* Lancer l'analyse (lexicale + syntaxique + semantique) */
    int res = yyparse();

    if (argc >= 2) fclose(yyin);

    /* Sortie JSON sur stdout pour l'interface Python */
    afficher_json_global();

    /* Liberer la memoire de l'AST */
    ast_liberer(g_ast_racine);

    return (res != 0 || g_erreurs > 0) ? 1 : 0;
}