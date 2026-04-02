CC      ?= cc
BISON   ?= bison
FLEX    ?= flex
CFLAGS  ?= -Wall -Wextra -std=c11

TARGET  = g-v1
PARSER_C = g-v1.tab.c
PARSER_H = g-v1.tab.h
LEX_C    = lex.yy.c
AST_OBJ  = ast.o

VALID_TESTS   := $(sort $(wildcard tests/valid_*.g))
INVALID_TESTS := $(sort $(wildcard tests/invalid_*.g))

.PHONY: all clean test test-valid test-invalid ast

all: $(TARGET)

$(PARSER_C) $(PARSER_H): g-v1.y ast.h
	$(BISON) -d -o $(PARSER_C) g-v1.y

$(LEX_C): g-v1.l $(PARSER_H)
	$(FLEX) -o $(LEX_C) g-v1.l

$(AST_OBJ): ast.c ast.h
	$(CC) $(CFLAGS) -c ast.c

$(TARGET): $(PARSER_C) $(LEX_C) $(AST_OBJ)
	$(CC) $(CFLAGS) -o $(TARGET) $(PARSER_C) $(LEX_C) $(AST_OBJ)

ast: $(TARGET)
	./$(TARGET) --ast tests/ast_demo.g

test: test-valid test-invalid

test-valid: $(TARGET)
	@set -e; \
	passed=0; total=0; \
	for f in $(VALID_TESTS); do \
		total=$$((total + 1)); \
		printf "[VALID]   %s ... " "$$f"; \
		if out=$$(./$(TARGET) "$$f" 2>&1); then \
			if [ -z "$$out" ]; then \
				echo "OK"; \
				passed=$$((passed + 1)); \
			else \
				echo "FAIL (deveria não imprimir nada)"; \
				printf "%s\n" "$$out"; \
				exit 1; \
			fi; \
		else \
			echo "FAIL"; \
			printf "%s\n" "$$out"; \
			exit 1; \
		fi; \
	done; \
	echo "Validos: $$passed/$$total passaram."

test-invalid: $(TARGET)
	@set -e; \
	passed=0; total=0; \
	for f in $(INVALID_TESTS); do \
		total=$$((total + 1)); \
		printf "[INVALID] %s ... " "$$f"; \
		expected=$$(cat "$${f%.g}.expected"); \
		out=$$(./$(TARGET) "$$f" 2>&1 || true); \
		if [ "$$out" = "$$expected" ]; then \
			echo "OK"; \
			passed=$$((passed + 1)); \
		else \
			echo "FAIL"; \
			echo "Esperado: $$expected"; \
			echo "Obtido:   $$out"; \
			exit 1; \
		fi; \
	done; \
	echo "Invalidos: $$passed/$$total passaram."

clean:
	rm -f $(TARGET) $(PARSER_C) $(PARSER_H) $(LEX_C) $(AST_OBJ)
