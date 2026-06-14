
#ifndef SYMBOLES_H
#define SYMBOLES_H

#include <stdio.h>

/* CONSTANTES */

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

/* STRUCTURE : ModuleUn module correspond a une matiere avec son coefficient et la note obtenue par l'etudiant*/
typedef struct {
    char   nom[128];   /* ex : "Algorithmique"              */
    int    coef;       /* coefficient (>= 1)                */
    double note;       /* note dans [0.0, 20.0]             */
} Module;


typedef struct {
    char   id[4];                    /* "S1" .. "S6"        */
    Module modules[MAX_MODULES];
    int    nb_modules;
    double moyenne;                  /* calculee apres parse */
} Semestre;


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


typedef struct {
    char     id[4];                   /* "L1", "L2", "L3"   */
    Etudiant etudiants[MAX_ETUDIANTS];
    int      nb_etudiants;
} Niveau;


typedef struct {
    char   annee[16];                 /* ex : "2025-2026"   */
    Niveau niveaux[MAX_NIVEAUX];
    int    nb_niveaux;
} Programme;



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

EntreeSymbole *symb_chercher(TableSymboles *table,
                              const char    *matricule);

/**
 * symb_afficher
 * Affiche le contenu de la table sur stderr (debug).
 */
void symb_afficher(TableSymboles *table);

double calculer_moyenne_semestre(Semestre *s);
double calculer_moyenne_annuelle(Etudiant *e);


void calculer_mention(Etudiant *e);


void calculer_rangs(Niveau *niv);

/* PROTOTYPES — Verification semantique*/

/** Verifie que la note est dans [NOTE_MIN, NOTE_MAX] */
void verifier_note(double note, int ligne);

/** Verifie que le coefficient est >= COEF_MIN */
void verifier_coef(int coef, int ligne);

/** Verifie la coherence semestre/niveau (L1->S1,S2 etc.) */
void verifier_semestre_niveau(const char *id_sem,
                               const char *id_niv);

/* PROTOTYPES — Sortie JSON*/

/** Affiche le programme parse au format JSON sur stdout */
void afficher_json(Programme *p);

/** Echappe les caracteres speciaux pour JSON */
void json_string_safe(const char *s);

#endif