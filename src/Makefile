# Makefile - Systeme de Gestion des Notes (SGN)
# Auteur  : [NOM1] [NOM2]
# Usage   : make        -> compile tout
#           make clean  -> supprime les fichiers generes
#           make test   -> lance le test sur test_valide.sgn

CC      = gcc
CFLAGS  = -Wall -Wextra -g
LIBS    = -lm
TARGET  = sgn

all: $(TARGET)

# Etape 1 : Bison genere parser.tab.c et parser.tab.h
parser.tab.c parser.tab.h: parser.y
	bison -d parser.y

# Etape 2 : Flex genere lex.yy.c (necessite parser.tab.h pour les tokens)
lex.yy.c: lexer.l parser.tab.h
	flex lexer.l

# Etape 3 : Compilation finale
$(TARGET): lex.yy.c parser.tab.c main.c
	$(CC) $(CFLAGS) lex.yy.c parser.tab.c main.c -o $(TARGET) $(LIBS)

# Test rapide
test: $(TARGET)
	./$(TARGET) ../tests/test_valide.sgn

# Nettoyage
clean:
	rm -f lex.yy.c parser.tab.c parser.tab.h $(TARGET)

.PHONY: all test clean