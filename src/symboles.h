/*
 * symboles.h - Table de symboles et structures de donnees
 * Projet  : Systeme de Gestion des Notes (SGN)
 * Module  : Compilation - Master 1 Informatique
 * Auteur  : [NOM1] [NOM2]
 * Date    : 2025-2026
 *
 * Ce fichier centralise :
 *   - Les constantes du langage SGN
 *   - Les structures de donnees (Module, Semestre, Etudiant,
 *     Niveau, Programme)
 *   - La table de symboles (matricules enregistres)
 *   - Les prototypes des fonctions semantiques et de calcul
 *
 * Il est inclus par parser.y, main.c et tout module C
 * qui a besoin d'acceder aux donnees parsees.
 */

#ifndef SYMBOLES_H
#define SYMBOLES_H

#include <stdio.h>

/* ========================================================
   CONSTANTES
   ======================================================== */

/* Limites du langage */
#define MAX_MODULES      50    /* modules par semestre       */
#define MAX_SEMESTRES     6    /* semestres par etudiant     */
#define MAX_ETUDIANTS   200    /* etudiants par niveau       */
#define MAX_NIVEAUX       3    /* L1, L2, L3                 */

/* Contraintes semantiques */
#define NOTE_MIN        0.0    /* note minimale valide       */
#define NOTE_MAX       20.0    /* note maximale valide       */
#define COEF_MIN          1    /* coefficient minimal valide */

/* Taille de la table de symboles */
#define TAILLE_TABLE    600    /* MAX_NIVEAUX * MAX_ETUDIANTS */

/* ========================================================
   STRUCTURE : Module
   Un module correspond a une matiere avec son coefficient
   et la note obtenue par l'etudiant.
   ======================================================== */
typedef struct {
    char   nom[128];   /* ex : "Algorithmique"              */
    int    coef;       /* coefficient (>= 1)                */
    double note;       /* note dans [0.0, 20.0]             */
} Module;

/* ========================================================
   STRUCTURE : Semestre
   Regroupe les modules d'un semestre et stocke la
   moyenne ponderee calculee apres le parsing.
   ======================================================== */
typedef struct {
    char   id[4];                    /* "S1" .. "S6"        */
    Module modules[MAX_MODULES];
    int    nb_modules;
    double moyenne;                  /* calculee apres parse */
} Semestre;

/* ========================================================
   STRUCTURE : Etudiant
   Contient les informations d'identite, les semestres,
   et les resultats calcules (moyenne, mention, rang).
   ======================================================== */
typedef struct {
    char     matricule[64];           /* identifiant unique  */
    char     nom[128];
    char     prenom[64];
    Semestre semestres[MAX_SEMESTRES];
    int      nb_semestres;
    double   moyenne_annuelle;        /* calculee            */
    char     mention[32];             /* "Bien", "Passable"  */
    char     decision[16];            /* "Admis"/"Ajourne"   */
    int      rang;                    /* rang dans le niveau */
} Etudiant;

/* ========================================================
   STRUCTURE : Niveau
   Regroupe tous les etudiants d'un meme niveau (L1/L2/L3).
   ======================================================== */
typedef struct {
    char     id[4];                   /* "L1", "L2", "L3"   */
    Etudiant etudiants[MAX_ETUDIANTS];
    int      nb_etudiants;
} Niveau;

/* ========================================================
   STRUCTURE : Programme
   Racine de toutes les donnees parsees.
   Contient l'annee academique et la liste des niveaux.
   ======================================================== */
typedef struct {
    char   annee[16];                 /* ex : "2025-2026"   */
    Niveau niveaux[MAX_NIVEAUX];
    int    nb_niveaux;
} Programme;

/* ========================================================
   TABLE DE SYMBOLES
   Sert a detecter les doublons de matricules.
   Chaque entree associe un matricule a son niveau.
   ======================================================== */

/* Une entree dans la table de symboles */
typedef struct {
    char matricule[64];   /* cle : matricule de l'etudiant  */
    char niveau_id[4];    /* valeur : niveau d'appartenance */
    int  ligne;           /* ligne de declaration           */
    int  occupe;          /* 1 si entree utilisee, 0 sinon  */
} EntreeSymbole;

/* La table de symboles globale */
typedef struct {
    EntreeSymbole entrees[TAILLE_TABLE];
    int           nb_entrees;
} TableSymboles;

/* ========================================================
   PROTOTYPES — Table de symboles
   ======================================================== */

/**
 * symb_initialiser
 * Remet a zero toutes les entrees de la table.
 * A appeler avant de commencer le parsing.
 */
void symb_initialiser(TableSymboles *table);

/**
 * symb_inserer
 * Insere un matricule dans la table.
 * Retourne 0 si OK, -1 si doublon detecte.
 * @param table      La table de symboles
 * @param matricule  Matricule a inserer
 * @param niveau_id  Niveau de l'etudiant (ex : "L1")
 * @param ligne      Numero de ligne dans le source
 */
int symb_inserer(TableSymboles *table,
                 const char    *matricule,
                 const char    *niveau_id,
                 int            ligne);

/**
 * symb_chercher
 * Cherche un matricule dans la table.
 * Retourne un pointeur vers l'entree si trouve, NULL sinon.
 */
EntreeSymbole *symb_chercher(TableSymboles *table,
                              const char    *matricule);

/**
 * symb_afficher
 * Affiche le contenu de la table sur stderr (debug).
 */
void symb_afficher(TableSymboles *table);

/* ========================================================
   PROTOTYPES — Calculs semantiques
   Implementes dans parser.y / un module dedie.
   ======================================================== */

/**
 * Calcule la moyenne ponderee d'un semestre :
 * M = sum(coef_i * note_i) / sum(coef_i)
 */
double calculer_moyenne_semestre(Semestre *s);

/**
 * Calcule la moyenne annuelle :
 * moyenne arithmetique des moyennes semestrielles
 */
double calculer_moyenne_annuelle(Etudiant *e);

/**
 * Determine la mention et la decision selon la moyenne :
 * >= 16 : Tres Bien | >= 14 : Bien | >= 12 : Assez Bien
 * >= 10 : Passable  | < 10  : Ajourne
 */
void calculer_mention(Etudiant *e);

/**
 * Calcule le rang de chaque etudiant dans un niveau
 * (1 = meilleure moyenne)
 */
void calculer_rangs(Niveau *niv);

/* ========================================================
   PROTOTYPES — Verification semantique
   ======================================================== */

/** Verifie que la note est dans [NOTE_MIN, NOTE_MAX] */
void verifier_note(double note, int ligne);

/** Verifie que le coefficient est >= COEF_MIN */
void verifier_coef(int coef, int ligne);

/** Verifie la coherence semestre/niveau (L1->S1,S2 etc.) */
void verifier_semestre_niveau(const char *id_sem,
                               const char *id_niv);

/* ========================================================
   PROTOTYPES — Sortie JSON
   ======================================================== */

/** Affiche le programme parse au format JSON sur stdout */
void afficher_json(Programme *p);

/** Echappe les caracteres speciaux pour JSON */
void json_string_safe(const char *s);

#endif /* SYMBOLES_H */