%code requires {
#include "ast.h"
}

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ast.h"

extern int yylineno;
extern char *yytext;
extern int yylex(void);
extern FILE *yyin;
ASTNode *ast_root = NULL;
static int g_print_ast = 0;

static void yyerror(const char *s);
%}

%define parse.error verbose
%locations

%union {
    char *str;
    ASTNode *node;
    int ival;
}

%token PRINCIPAL INT CAR LEIA ESCREVA NOVALINHA
%token SE ENTAO SENAO FIMSE ENQUANTO
%token OU E IGUAL DIFERENTE MAIORIGUAL MENORIGUAL
%token <str> IDENTIFICADOR CADEIACARACTERES CARCONST INTCONST

%type <node> Programa DeclPrograma Bloco VarSection ListaDeclVar VarDecl IdList ListaComando Comando
%type <node> Expr OrExpr AndExpr EqExpr DesigExpr AddExpr MulExpr UnExpr PrimExpr
%type <ival> Tipo

%start Programa

%%

Programa
    : DeclPrograma
      {
          ast_root = $1;
          $$ = $1;
      }
    ;

DeclPrograma
    : PRINCIPAL Bloco
      {
          $$ = ast_make_program($2, @1.first_line);
      }
    ;

Bloco
    : '{' ListaComando '}'
      {
          $$ = ast_make_block(NULL, $2, @1.first_line);
      }
    | VarSection '{' ListaComando '}'
      {
          $$ = ast_make_block($1, $3, @2.first_line);
      }
    ;

VarSection
    : '{' ListaDeclVar '}'
      {
          $$ = $2;
      }
    ;

ListaDeclVar
    : VarDecl
      {
          $$ = $1;
      }
    | ListaDeclVar VarDecl
      {
          $$ = ast_append($1, $2);
      }
    ;

VarDecl
    : IdList ':' Tipo ';'
      {
          $$ = ast_build_decl_list($1, (ASTDataType)$3);
      }
    ;

IdList
    : IDENTIFICADOR
      {
          $$ = ast_make_ident($1, @1.first_line);
          free($1);
      }
    | IdList ',' IDENTIFICADOR
      {
          $$ = ast_append($1, ast_make_ident($3, @3.first_line));
          free($3);
      }
    ;

Tipo
    : INT
      {
          $$ = AST_TYPE_INT;
      }
    | CAR
      {
          $$ = AST_TYPE_CAR;
      }
    ;

ListaComando
    : Comando
      {
          $$ = $1;
      }
    | ListaComando Comando
      {
          $$ = ast_append($1, $2);
      }
    ;

Comando
    : ';'
      {
          $$ = ast_make_empty_stmt(@1.first_line);
      }
    | Expr ';'
      {
          $$ = $1;
      }
    | LEIA IDENTIFICADOR ';'
      {
          ASTNode *id = ast_make_ident($2, @2.first_line);
          $$ = ast_make_read(id, @1.first_line);
          free($2);
      }
    | ESCREVA Expr ';'
      {
          $$ = ast_make_write($2, @1.first_line);
      }
    | ESCREVA CADEIACARACTERES ';'
      {
          ASTNode *s = ast_make_string_literal($2, @2.first_line);
          $$ = ast_make_write(s, @1.first_line);
          free($2);
      }
    | NOVALINHA ';'
      {
          $$ = ast_make_newline(@1.first_line);
      }
    | SE '(' Expr ')' ENTAO Comando FIMSE
      {
          $$ = ast_make_if($3, $6, NULL, @1.first_line);
      }
    | SE '(' Expr ')' ENTAO Comando SENAO Comando FIMSE
      {
          $$ = ast_make_if($3, $6, $8, @1.first_line);
      }
    | ENQUANTO '(' Expr ')' Comando
      {
          $$ = ast_make_while($3, $5, @1.first_line);
      }
    | Bloco
      {
          $$ = $1;
      }
    ;

Expr
    : OrExpr
      {
          $$ = $1;
      }
    | IDENTIFICADOR '=' Expr
      {
          ASTNode *lhs = ast_make_ident($1, @1.first_line);
          $$ = ast_make_assign(lhs, $3, @2.first_line);
          free($1);
      }
    ;

OrExpr
    : AndExpr
      {
          $$ = $1;
      }
    | OrExpr OU AndExpr
      {
          $$ = ast_make_binary_op("||", $1, $3, @2.first_line);
      }
    ;

AndExpr
    : EqExpr
      {
          $$ = $1;
      }
    | AndExpr E EqExpr
      {
          $$ = ast_make_binary_op("&", $1, $3, @2.first_line);
      }
    ;

EqExpr
    : DesigExpr
      {
          $$ = $1;
      }
    | EqExpr IGUAL DesigExpr
      {
          $$ = ast_make_binary_op("==", $1, $3, @2.first_line);
      }
    | EqExpr DIFERENTE DesigExpr
      {
          $$ = ast_make_binary_op("!=", $1, $3, @2.first_line);
      }
    ;

DesigExpr
    : AddExpr
      {
          $$ = $1;
      }
    | DesigExpr '<' AddExpr
      {
          $$ = ast_make_binary_op("<", $1, $3, @2.first_line);
      }
    | DesigExpr '>' AddExpr
      {
          $$ = ast_make_binary_op(">", $1, $3, @2.first_line);
      }
    | DesigExpr MAIORIGUAL AddExpr
      {
          $$ = ast_make_binary_op(">=", $1, $3, @2.first_line);
      }
    | DesigExpr MENORIGUAL AddExpr
      {
          $$ = ast_make_binary_op("<=", $1, $3, @2.first_line);
      }
    ;

AddExpr
    : MulExpr
      {
          $$ = $1;
      }
    | AddExpr '+' MulExpr
      {
          $$ = ast_make_binary_op("+", $1, $3, @2.first_line);
      }
    | AddExpr '-' MulExpr
      {
          $$ = ast_make_binary_op("-", $1, $3, @2.first_line);
      }
    ;

MulExpr
    : UnExpr
      {
          $$ = $1;
      }
    | MulExpr '*' UnExpr
      {
          $$ = ast_make_binary_op("*", $1, $3, @2.first_line);
      }
    | MulExpr '/' UnExpr
      {
          $$ = ast_make_binary_op("/", $1, $3, @2.first_line);
      }
    ;

UnExpr
    : PrimExpr
      {
          $$ = $1;
      }
    | '-' PrimExpr
      {
          $$ = ast_make_unary_op("-", $2, @1.first_line);
      }
    | '!' PrimExpr
      {
          $$ = ast_make_unary_op("!", $2, @1.first_line);
      }
    ;

PrimExpr
    : IDENTIFICADOR
      {
          $$ = ast_make_ident($1, @1.first_line);
          free($1);
      }
    | CARCONST
      {
          $$ = ast_make_char_const($1, @1.first_line);
          free($1);
      }
    | INTCONST
      {
          $$ = ast_make_int_const($1, @1.first_line);
          free($1);
      }
    | '(' Expr ')'
      {
          $$ = $2;
      }
    ;

%%

static void yyerror(const char *s) {
    (void)s;
    fprintf(stdout, "ERRO: ERRO SINTATICO %d\n", yylineno);
}

static void usage(const char *progname) {
    fprintf(stderr, "Uso: %s [--ast] arquivo.g\n", progname);
}

int main(int argc, char **argv) {
    const char *input_path = NULL;

    if (argc == 2) {
        input_path = argv[1];
    } else if (argc == 3 && strcmp(argv[1], "--ast") == 0) {
        g_print_ast = 1;
        input_path = argv[2];
    } else {
        usage(argv[0]);
        return EXIT_FAILURE;
    }

    yyin = fopen(input_path, "r");
    if (yyin == NULL) {
        perror(input_path);
        return EXIT_FAILURE;
    }

    if (yyparse() == 0) {
        if (g_print_ast && ast_root != NULL) {
            ast_print(stdout, ast_root);
        }
        ast_free(ast_root);
        fclose(yyin);
        return EXIT_SUCCESS;
    }

    ast_free(ast_root);
    fclose(yyin);
    return EXIT_FAILURE;
}
