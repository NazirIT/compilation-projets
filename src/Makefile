CC      = gcc
CFLAGS  = -Wall -Wextra -g
LIBS    = -lm
TARGET  = sgn

# Fichiers sources C (hors fichiers generes par flex/bison)
SRCS_C  = main.c Symboles.c ast.c

# Fichiers objets finaux
OBJS    = lex.yy.o parser.tab.o symboles.o ast.o main.o


# Cible principale

all: $(TARGET)

# Etape 1 : Bison -> parser.tab.c + parser.tab.h

parser.tab.c parser.tab.h: parser.y
	bison -d parser.y

# Etape 2 : Flex -> lex.yy.c
# (necessite parser.tab.h pour les tokens)

lex.yy.c: lexer.l parser.tab.h
	flex lexer.l

# Etape 3 : Compilation des objets

lex.yy.o: lex.yy.c parser.tab.h
	$(CC) $(CFLAGS) -c lex.yy.c -o lex.yy.o

parser.tab.o: parser.tab.c symboles.h ast.h
	$(CC) $(CFLAGS) -c parser.tab.c -o parser.tab.o

symboles.o: Symboles.c symboles.h
	$(CC) $(CFLAGS) -c Symboles.c -o symboles.o

ast.o: ast.c ast.h
	$(CC) $(CFLAGS) -c ast.c -o ast.o

main.o: main.c symboles.h ast.h
	$(CC) $(CFLAGS) -c main.c -o main.o

# Etape 4 : Edition de liens -> binaire final

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o $(TARGET) $(LIBS)

# Tests

test: $(TARGET)
	@echo "=== Test fichier valide ==="
	./$(TARGET) ../tests/test_valide.sgn

test_err: $(TARGET)
	@echo "=== Test erreurs semantiques ==="
	./$(TARGET) ../tests/test_erreur_sem.sgn 2>&1

test_lex: $(TARGET)
	@echo "=== Test erreurs lexicales ==="
	./$(TARGET) ../tests/test_erreur_lex.sgn 2>&1

# Debug : active les traces Bison (YYDEBUG)

debug: CFLAGS += -DYYDEBUG=1
debug: clean $(TARGET)

# Nettoyage

clean:
	rm -f lex.yy.c lex.yy.o \
	      parser.tab.c parser.tab.h parser.tab.o \
	      symboles.o ast.o main.o \
	      $(TARGET)

.PHONY: all test test_err test_lex debug clean