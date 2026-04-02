%option noyywrap yylineno noinput nounput

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "g-v1.tab.h"

extern YYLTYPE yylloc;

static int comment_start_line = 1;
static int string_start_line = 1;

static void lexical_error_at(const char *msg, int line);
static char *dup_text(const char *src);
static void set_token_line(int line);
%}

%x COMMENT STRING

LETRA      [A-Za-z_]
DIGITO     [0-9]
ID         {LETRA}({LETRA}|{DIGITO})*
INTLIT     {DIGITO}+
CAR_ESC    \.
CAR_BODY   ([^\\\n']|{CAR_ESC})
CARACTERE  \'{CAR_BODY}\'

%%

[ \t\r]+                    { }
\n                          { }

"/*"                        { comment_start_line = yylineno; BEGIN(COMMENT); }
<COMMENT>"*/"               { BEGIN(INITIAL); }
<COMMENT>\n                 { }
<COMMENT>.                  { }
<COMMENT><<EOF>>            { lexical_error_at("COMENTARIO NAO TERMINA", comment_start_line); }

\"                          { string_start_line = yylineno; BEGIN(STRING); yymore(); }
<STRING>[^\\\n\"]+          { yymore(); }
<STRING>\\[^\n]             { yymore(); }
<STRING>\"                  { BEGIN(INITIAL); yylval.str = dup_text(yytext); set_token_line(string_start_line); return CADEIACARACTERES; }
<STRING>\n                  { lexical_error_at("CADEIA DE CARACTERES OCUPA MAIS DE UMA LINHA", string_start_line); }
<STRING><<EOF>>             { lexical_error_at("CADEIA DE CARACTERES OCUPA MAIS DE UMA LINHA", string_start_line); }

"principal"                 { set_token_line(yylineno); return PRINCIPAL; }
"int"                       { set_token_line(yylineno); return INT; }
"car"                       { set_token_line(yylineno); return CAR; }
"leia"                      { set_token_line(yylineno); return LEIA; }
"escreva"                   { set_token_line(yylineno); return ESCREVA; }
"novalinha"                 { set_token_line(yylineno); return NOVALINHA; }
"se"                        { set_token_line(yylineno); return SE; }
"entao"                     { set_token_line(yylineno); return ENTAO; }
"senao"                     { set_token_line(yylineno); return SENAO; }
"fimse"                     { set_token_line(yylineno); return FIMSE; }
"enquanto"                  { set_token_line(yylineno); return ENQUANTO; }

"||"                        { set_token_line(yylineno); return OU; }
"&"                         { set_token_line(yylineno); return E; }
"=="                        { set_token_line(yylineno); return IGUAL; }
"!="                        { set_token_line(yylineno); return DIFERENTE; }
">="                        { set_token_line(yylineno); return MAIORIGUAL; }
"<="                        { set_token_line(yylineno); return MENORIGUAL; }

{CARACTERE}                 { yylval.str = dup_text(yytext); set_token_line(yylineno); return CARCONST; }
{INTLIT}                    { yylval.str = dup_text(yytext); set_token_line(yylineno); return INTCONST; }
{ID}                        { yylval.str = dup_text(yytext); set_token_line(yylineno); return IDENTIFICADOR; }

[{}();,:+*/<>=!-]           { set_token_line(yylineno); return yytext[0]; }

<<EOF>>                     { return 0; }

.                           { lexical_error_at("CARACTERE INVALIDO", yylineno); }

%%

static void lexical_error_at(const char *msg, int line) {
    fprintf(stdout, "ERRO: %s %d\n", msg, line);
    exit(EXIT_FAILURE);
}

static char *dup_text(const char *src) {
    size_t n = strlen(src) + 1;
    char *dst = (char *)malloc(n);
    if (dst == NULL) {
        fprintf(stderr, "ERRO: falha de memoria\n");
        exit(EXIT_FAILURE);
    }
    memcpy(dst, src, n);
    return dst;
}

static void set_token_line(int line) {
    yylloc.first_line = line;
    yylloc.last_line = line;
    yylloc.first_column = 1;
    yylloc.last_column = 1;
}
