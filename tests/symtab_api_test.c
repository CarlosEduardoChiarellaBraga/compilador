#include <assert.h>
#include <stdio.h>

#include "symtab.h"

int main(void) {
    SymbolTableStack stack;
    SymbolEntry *entry;

    symtab_init(&stack);
    assert(symtab_lookup(&stack, "x") == NULL);

    assert(symtab_push_scope(&stack) != NULL);
    entry = symtab_insert(&stack, "x", AST_TYPE_INT, 1);
    assert(entry != NULL);
    assert(symtab_lookup(&stack, "x") == entry);
    assert(symtab_lookup_current(&stack, "x") == entry);

    assert(symtab_push_scope(&stack) != NULL);
    assert(symtab_lookup(&stack, "x") != NULL);

    entry = symtab_insert(&stack, "y", AST_TYPE_CAR, 2);
    assert(entry != NULL);
    entry = symtab_insert(&stack, "x", AST_TYPE_CAR, 3);
    assert(entry != NULL);
    assert(symtab_lookup_current(&stack, "x")->type == AST_TYPE_CAR);
    assert(symtab_lookup(&stack, "x")->type == AST_TYPE_CAR);

    assert(symtab_pop_scope(&stack) == 1);
    assert(symtab_lookup(&stack, "y") == NULL);
    assert(symtab_lookup(&stack, "x") != NULL);
    assert(symtab_lookup(&stack, "x")->type == AST_TYPE_INT);

    assert(symtab_pop_scope(&stack) == 1);
    assert(symtab_lookup(&stack, "x") == NULL);
    assert(symtab_pop_scope(&stack) == 0);

    symtab_destroy(&stack);
    puts("OK");
    return 0;
}
