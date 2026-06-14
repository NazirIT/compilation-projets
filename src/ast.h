

#ifndef AST_H
#define AST_H

#include <stdio.h>

/* Types de noeuds de l'AST*/

typedef enum {
    NODE_PROGRAMME,   /* racine : contient l'annee           */
    NODE_NIVEAU,      /* L1, L2 ou L3                        */
    NODE_ETUDIANT,    /* bloc etudiant                       */
    NODE_MATRICULE,   /* champ matricule (feuille)           */
    NODE_NOM,         /* champ nom      (feuille)            */
    NODE_PRENOM,      /* champ prenom   (feuille)            */
    NODE_SEMESTRE,    /* S1..S6                              */
    NODE_MODULE,      /* un module avec coef et note         */
    NODE_ANNEE        /* valeur de l'annee academique        */
} NodeType;


typedef union {
    char   *chaine;   /* pour NODE_PROGRAMME, NODE_NIVEAU, NODE_ETUDIANT, NODE_MATRICULE, NODE_NOM, NODE_PRENOM, NODE_SEMESTRE, NODE_ANNEE, NODE_MODULE (nom)       */
    int     entier;   /* pour le coefficient d'un module     */
    double  reel;     /* pour la note d'un module            */
} NodeValue;


typedef struct ASTNode {
    NodeType  type;           /* type du noeud               */
    NodeValue valeur;         /* valeur principale           */
    /* Donnees supplementaires selon le type :
       Pour NODE_MODULE : coef et note en plus du nom        */
    int       coef;           /* coefficient (NODE_MODULE)   */
    double    note;           /* note        (NODE_MODULE)   */

    /* Liste des enfants (tableau dynamique) */
    struct ASTNode **enfants;
    int              nb_enfants;
    int              capacite;  /* capacite allouee           */

    /* Numero de ligne dans le fichier source (pour erreurs) */
    int ligne;
} ASTNode;

/* Prototypes des fonctions AST  */

/**
 * ast_creer_noeud
 * Alloue et initialise un nouveau noeud.
 * @param type   Type du noeud
 * @param valeur Valeur chaine (peut etre NULL)
 * @param ligne  Numero de ligne source
 * @return Pointeur vers le noeud cree (NULL si echec)
 */
ASTNode *ast_creer_noeud(NodeType type, const char *valeur, int ligne);

/**
 * ast_creer_module
 * Cree un noeud MODULE avec nom, coef et note.
 * @param nom   Nom du module
 * @param coef  Coefficient
 * @param note  Note obtenue
 * @param ligne Numero de ligne source
 */
ASTNode *ast_creer_module(const char *nom, int coef,
                           double note, int ligne);

/**
 * ast_ajouter_enfant
 * Ajoute un noeud enfant a un noeud parent.
 * @param parent Noeud parent
 * @param enfant Noeud a ajouter comme enfant
 */
void ast_ajouter_enfant(ASTNode *parent, ASTNode *enfant);

/**
 * ast_afficher
 * Affiche l'arbre sur stderr de facon indentee (debug).
 * @param noeud  Racine du sous-arbre a afficher
 * @param niveau Profondeur (0 pour la racine)
 */
void ast_afficher(ASTNode *noeud, int niveau);

/**
 * ast_liberer
 * Libere recursivement toute la memoire de l'arbre.
 * @param noeud Racine du sous-arbre a liberer
 */
void ast_liberer(ASTNode *noeud);

/**
 * ast_nom_type
 * Retourne le nom lisible d'un type de noeud (debug).
 */
const char *ast_nom_type(NodeType type);

#endif /* AST_H */