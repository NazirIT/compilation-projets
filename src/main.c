/*
 * main.c - Point d'entree du programme SGN
 * Projet  : Systeme de Gestion des Notes
 * Auteur  : [NOM1] [NOM2]
 * Date    : 2025-2026
 *
 * Usage : ./sgn fichier.sgn
 *         ./sgn < fichier.sgn
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Declares dans parser.tab.c */
extern int  yyparse(void);
extern FILE *yyin;
extern int  g_erreurs;
extern void afficher_json();

/* La structure programme globale */
/* (declaree dans parser.y, accessible via extern) */

int main(int argc, char *argv[]) {

    /* Lecture depuis un fichier ou stdin */
    if (argc >= 2) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr,
                "[ERREUR] Impossible d'ouvrir le fichier : %s\n",
                argv[1]);
            return 1;
        }
    } else {
        yyin = stdin;
    }

    /* Lancer l'analyse syntaxique (qui appelle le lexer) */
    int res = yyparse();

    if (argc >= 2) fclose(yyin);

    /* Afficher le JSON sur stdout (lu par Python) */
    /* meme en cas d'erreur partielle, on affiche ce qu'on a */
    extern void afficher_json_global(void);
    afficher_json_global();

    /* Code de retour : 0 si OK, 1 si erreurs */
    return (res != 0 || g_erreurs > 0) ? 1 : 0;
}