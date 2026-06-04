/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_PARSER_TAB_H_INCLUDED
# define YY_YY_PARSER_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 284,                 /* "invalid token"  */
    TOKEN_ANNEE = 258,             /* TOKEN_ANNEE  */
    TOKEN_NIVEAU = 259,            /* TOKEN_NIVEAU  */
    TOKEN_ETUDIANT = 260,          /* TOKEN_ETUDIANT  */
    TOKEN_MATRICULE = 261,         /* TOKEN_MATRICULE  */
    TOKEN_NOM = 262,               /* TOKEN_NOM  */
    TOKEN_PRENOM = 263,            /* TOKEN_PRENOM  */
    TOKEN_SEMESTRE = 264,          /* TOKEN_SEMESTRE  */
    TOKEN_MODULE = 265,            /* TOKEN_MODULE  */
    TOKEN_COEF = 266,              /* TOKEN_COEF  */
    TOKEN_NOTE = 267,              /* TOKEN_NOTE  */
    TOKEN_L1 = 268,                /* TOKEN_L1  */
    TOKEN_L2 = 269,                /* TOKEN_L2  */
    TOKEN_L3 = 270,                /* TOKEN_L3  */
    TOKEN_S1 = 271,                /* TOKEN_S1  */
    TOKEN_S2 = 272,                /* TOKEN_S2  */
    TOKEN_S3 = 273,                /* TOKEN_S3  */
    TOKEN_S4 = 274,                /* TOKEN_S4  */
    TOKEN_S5 = 275,                /* TOKEN_S5  */
    TOKEN_S6 = 276,                /* TOKEN_S6  */
    TOKEN_ENTIER = 277,            /* TOKEN_ENTIER  */
    TOKEN_REEL = 278,              /* TOKEN_REEL  */
    TOKEN_STRING = 279,            /* TOKEN_STRING  */
    TOKEN_LBRACE = 280,            /* TOKEN_LBRACE  */
    TOKEN_RBRACE = 281,            /* TOKEN_RBRACE  */
    TOKEN_COLON = 282,             /* TOKEN_COLON  */
    TOKEN_ERREUR = 283             /* TOKEN_ERREUR  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 49 "parser.y"

    int entier;
    double reel;
    char *chaine;

#line 98 "parser.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;


int yyparse (void);


#endif /* !YY_YY_PARSER_TAB_H_INCLUDED  */
