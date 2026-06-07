

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"

/* Capacite initiale du tableau d'enfants */
#define CAPACITE_INITIALE 4

/* ========================================================
   ast_creer_noeud
   Alloue un noeud, copie la valeur chaine si fournie.
   ======================================================== */
ASTNode *ast_creer_noeud(NodeType type, const char *valeur, int ligne)
{
    ASTNode *n = (ASTNode *)malloc(sizeof(ASTNode));
    if (!n)
    {
        fprintf(stderr, "[AST] Erreur : allocation memoire impossible\n");
        return NULL;
    }

    n->type = type;
    n->coef = 0;
    n->note = 0.0;
    n->ligne = ligne;
    n->nb_enfants = 0;
    n->capacite = CAPACITE_INITIALE;

    /* Copier la valeur chaine si elle est fournie */
    if (valeur != NULL)
    {
        n->valeur.chaine = strdup(valeur);
        if (!n->valeur.chaine)
        {
            fprintf(stderr, "[AST] Erreur : strdup impossible\n");
            free(n);
            return NULL;
        }
    }
    else
    {
        n->valeur.chaine = NULL;
    }

    /* Allouer le tableau d'enfants */
    n->enfants = (ASTNode **)malloc(
        n->capacite * sizeof(ASTNode *));
    if (!n->enfants)
    {
        fprintf(stderr, "[AST] Erreur : allocation enfants impossible\n");
        free(n->valeur.chaine);
        free(n);
        return NULL;
    }

    return n;
}

/* ========================================================
   ast_creer_module
   Cree un noeud MODULE avec ses trois attributs :
   nom (chaine), coef (entier), note (reel).
   ======================================================== */
ASTNode *ast_creer_module(const char *nom, int coef,
                          double note, int ligne)
{
    ASTNode *n = ast_creer_noeud(NODE_MODULE, nom, ligne);
    if (!n)
        return NULL;
    n->coef = coef;
    n->note = note;
    return n;
}

/* ========================================================
   ast_ajouter_enfant
   Ajoute enfant au tableau d'enfants de parent.
   Redimensionne le tableau si necessaire (x2).
   ======================================================== */
void ast_ajouter_enfant(ASTNode *parent, ASTNode *enfant)
{
    if (!parent || !enfant)
        return;

    /* Agrandir le tableau si plein */
    if (parent->nb_enfants >= parent->capacite)
    {
        int nouvelle_cap = parent->capacite * 2;
        ASTNode **nouveau = (ASTNode **)realloc(
            parent->enfants,
            nouvelle_cap * sizeof(ASTNode *));
        if (!nouveau)
        {
            fprintf(stderr,
                    "[AST] Erreur : realloc enfants impossible\n");
            return;
        }
        parent->enfants = nouveau;
        parent->capacite = nouvelle_cap;
    }

    parent->enfants[parent->nb_enfants] = enfant;
    parent->nb_enfants++;
}

/* ========================================================
   ast_nom_type
   Retourne une chaine lisible pour un type de noeud.
   Utile pour l'affichage de debug.
   ======================================================== */
const char *ast_nom_type(NodeType type)
{
    switch (type)
    {
    case NODE_PROGRAMME:
        return "PROGRAMME";
    case NODE_ANNEE:
        return "ANNEE";
    case NODE_NIVEAU:
        return "NIVEAU";
    case NODE_ETUDIANT:
        return "ETUDIANT";
    case NODE_MATRICULE:
        return "MATRICULE";
    case NODE_NOM:
        return "NOM";
    case NODE_PRENOM:
        return "PRENOM";
    case NODE_SEMESTRE:
        return "SEMESTRE";
    case NODE_MODULE:
        return "MODULE";
    default:
        return "INCONNU";
    }
}

/* ========================================================
   ast_afficher
   Affiche recursivement l'arbre avec indentation.
   Chaque niveau d'arbre ajoute 2 espaces.
   Exemple de sortie :
     [PROGRAMME] annee=2025-2026
       [NIVEAU] L1
         [ETUDIANT]
           [MATRICULE] L1-2025-001
           [SEMESTRE] S1
             [MODULE] Algorithmique coef=3 note=14.50
   ======================================================== */
void ast_afficher(ASTNode *noeud, int niveau)
{
    int i;
    if (!noeud)
        return;

    /* Indentation */
    for (i = 0; i < niveau; i++)
        fprintf(stderr, "  ");

    /* Afficher le type */
    fprintf(stderr, "[%s]", ast_nom_type(noeud->type));

    /* Afficher la valeur selon le type */
    switch (noeud->type)
    {
    case NODE_MODULE:
        fprintf(stderr, " \"%s\" coef=%d note=%.2f",
                noeud->valeur.chaine ? noeud->valeur.chaine : "",
                noeud->coef, noeud->note);
        break;
    case NODE_PROGRAMME:
    case NODE_ANNEE:
    case NODE_NIVEAU:
    case NODE_ETUDIANT:
    case NODE_MATRICULE:
    case NODE_NOM:
    case NODE_PRENOM:
    case NODE_SEMESTRE:
        if (noeud->valeur.chaine)
            fprintf(stderr, " %s", noeud->valeur.chaine);
        break;
    default:
        break;
    }

    /* Afficher le numero de ligne */
    fprintf(stderr, "  (ligne %d)\n", noeud->ligne);

    /* Afficher recursivement les enfants */
    for (i = 0; i < noeud->nb_enfants; i++)
    {
        ast_afficher(noeud->enfants[i], niveau + 1);
    }
}

/* ========================================================
   ast_liberer
   Libere recursivement toute la memoire allouee par l'AST.
   Parcours post-ordre : on libere les enfants avant le parent.
   ======================================================== */
void ast_liberer(ASTNode *noeud)
{
    int i;
    if (!noeud)
        return;

    /* Liberer recursivement chaque enfant */
    for (i = 0; i < noeud->nb_enfants; i++)
    {
        ast_liberer(noeud->enfants[i]);
    }

    /* Liberer le tableau d'enfants */
    free(noeud->enfants);

    /* Liberer la valeur chaine si elle existe */
    if (noeud->valeur.chaine)
    {
        free(noeud->valeur.chaine);
    }

    /* Liberer le noeud lui-meme */
    free(noeud);
}