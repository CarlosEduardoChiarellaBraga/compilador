CC ?= cc
CFLAGS ?= -Wall -Wextra -std=c11
BISON ?= bison
FLEX ?= flex

TARGET = g-v1
TEST_API_BIN = tests/symtab_api_test

OBJS = g-v1.tab.o lex.yy.o ast.o symtab.o semantic.o

.PHONY: all clean test test-valid test-invalid test-symtab test-symtab-api ast symtab

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS)

g-v1.tab.c g-v1.tab.h: g-v1.y ast.h symtab.h semantic.h
	$(BISON) -d -o g-v1.tab.c g-v1.y

lex.yy.c: g-v1.l g-v1.tab.h
	$(FLEX) -o lex.yy.c g-v1.l

g-v1.tab.o: g-v1.tab.c ast.h symtab.h semantic.h
	$(CC) $(CFLAGS) -c g-v1.tab.c

lex.yy.o: lex.yy.c g-v1.tab.h
	$(CC) $(CFLAGS) -c lex.yy.c

ast.o: ast.c ast.h
	$(CC) $(CFLAGS) -c ast.c

symtab.o: symtab.c symtab.h ast.h
	$(CC) $(CFLAGS) -c symtab.c

semantic.o: semantic.c semantic.h symtab.h ast.h
	$(CC) $(CFLAGS) -c semantic.c

$(TEST_API_BIN): tests/symtab_api_test.c symtab.o ast.o
	$(CC) $(CFLAGS) -I. -o $@ tests/symtab_api_test.c symtab.o ast.o

ast: $(TARGET)
	./$(TARGET) --ast tests/valid_02_nested_scopes.g

symtab: $(TARGET)
	./$(TARGET) --symtab tests/symtab_01_nested.g

test: test-valid test-invalid test-symtab test-symtab-api

test-valid: $(TARGET)
	@set -e; \
	for f in tests/valid_*.g; do \
		printf "[VALID]   %s ... " "$$f"; \
		out=$$(./$(TARGET) "$$f"); \
		if [ -n "$$out" ]; then \
			echo "FAIL"; \
			echo "$$out"; \
			exit 1; \
		fi; \
		echo "OK"; \
	done

test-invalid: $(TARGET)
	@set -e; \
	for f in tests/invalid_*.g; do \
		exp="tests/expected/$$(basename $$f .g).out"; \
		printf "[INVALID] %s ... " "$$f"; \
		out=$$(./$(TARGET) "$$f" 2>&1 || true); \
		expected=$$(cat "$$exp"); \
		if [ "$$out" != "$$expected" ]; then \
			echo "FAIL"; \
			echo "Esperado: $$expected"; \
			echo "Obtido:   $$out"; \
			exit 1; \
		fi; \
		echo "OK"; \
	done

test-symtab: $(TARGET)
	@set -e; \
	for f in tests/symtab_*.g; do \
		exp="tests/expected/$$(basename $$f .g).out"; \
		printf "[SYMTAB]  %s ... " "$$f"; \
		out=$$(./$(TARGET) --symtab "$$f"); \
		expected=$$(cat "$$exp"); \
		if [ "$$out" != "$$expected" ]; then \
			echo "FAIL"; \
			echo "Esperado:"; \
			printf "%s\n" "$$expected"; \
			echo "Obtido:"; \
			printf "%s\n" "$$out"; \
			exit 1; \
		fi; \
		echo "OK"; \
	done

test-symtab-api: $(TEST_API_BIN)
	@printf "[API]     tests/symtab_api_test.c ... "
	@./$(TEST_API_BIN)
	@echo "OK"

clean:
	rm -f $(TARGET) $(OBJS) g-v1.tab.c g-v1.tab.h lex.yy.c $(TEST_API_BIN)
