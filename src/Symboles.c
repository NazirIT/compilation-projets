

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symboles.h"


void symb_initialiser(TableSymboles *table) {
    int i;
    for (i = 0; i < TAILLE_TABLE; i++) {
        table->entrees[i].occupe = 0;
        table->entrees[i].matricule[0] = '\0';
        table->entrees[i].niveau_id[0] = '\0';
        table->entrees[i].ligne = 0;
    }
    table->nb_entrees = 0;
}


int symb_inserer(TableSymboles *table,
                 const char    *matricule,
                 const char    *niveau_id,
                 int            ligne) {

    /* Verifier si la table est pleine */
    if (table->nb_entrees >= TAILLE_TABLE) {
        fprintf(stderr,
            "[TABLE SYMBOLES] Erreur : table pleine "
            "(max %d entrees)\n", TAILLE_TABLE);
        return -2;
    }

    /* Chercher un doublon d'abord */
    if (symb_chercher(table, matricule) != NULL) {
        fprintf(stderr,
            "[ERREUR SEMANTIQUE] Ligne %d : "
            "Matricule '%s' deja declare dans le niveau %s\n",
            ligne, matricule, niveau_id);
        return -1;
    }

    /* Inserer dans la premiere case libre */
    int i;
    for (i = 0; i < TAILLE_TABLE; i++) {
        if (!table->entrees[i].occupe) {
            strncpy(table->entrees[i].matricule, matricule,
                    sizeof(table->entrees[i].matricule) - 1);
            strncpy(table->entrees[i].niveau_id, niveau_id,
                    sizeof(table->entrees[i].niveau_id) - 1);
            table->entrees[i].ligne  = ligne;
            table->entrees[i].occupe = 1;
            table->nb_entrees++;
            return 0;
        }
    }
    return -2;
}


EntreeSymbole *symb_chercher(TableSymboles *table,
                              const char    *matricule) {
    int i;
    for (i = 0; i < TAILLE_TABLE; i++) {
        if (table->entrees[i].occupe &&
            strcmp(table->entrees[i].matricule, matricule) == 0) {
            return &table->entrees[i];
        }
    }
    return NULL;
}


void symb_afficher(TableSymboles *table) {
    int i;
    fprintf(stderr, "=== Table de Symboles (%d entree(s)) ===\n",
            table->nb_entrees);
    fprintf(stderr, "%-5s  %-20s  %-6s  %s\n",
            "Idx", "Matricule", "Niveau", "Ligne");
    fprintf(stderr, "---------------------------------------------\n");
    for (i = 0; i < TAILLE_TABLE; i++) {
        if (table->entrees[i].occupe) {
            fprintf(stderr, "%-5d  %-20s  %-6s  %d\n",
                    i,
                    table->entrees[i].matricule,
                    table->entrees[i].niveau_id,
                    table->entrees[i].ligne);
        }
    }
    fprintf(stderr, "---------------------------------------------\n");
}