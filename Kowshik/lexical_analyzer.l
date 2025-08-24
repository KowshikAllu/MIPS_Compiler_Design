%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
%}

%%
"input"         { return INPUT; }
"output"        { return OUTPUT; }
"return"        { return RETURN; }
"for"           { return FOR; }
"if"            { return IF; }
"else"          { return ELSE; }
"continue"      { return CONTINUE; }
"break"         { return BREAK; }

"int"           { return INT; }
"float"         { return FLOAT; }

[0-9]+\.[0-9]+  { yylval.fval = atof(yytext); return FLOAT_LITERAL; }
[0-9]+          { yylval.ival = atoi(yytext); return INT_LITERAL; }

\"[^\"]*\"      { yylval.sval = strdup(yytext); return STRING; }

[a-zA-Z_][a-zA-Z0-9_]* { yylval.sval = strdup(yytext); return IDENTIFIER; }

"=="            { return EQ; }
"!="            { return NEQ; }
"<="            { return LE; }
">="            { return GE; }

"//".*          ;   /* skip single-line comments */

[=;+\-*/%<>{}(),]  { return yytext[0]; }

[ \t\r\n]+      ;   // ignore whitespace

.               { printf("Unknown char: %s\n", yytext); }

%%
int yywrap(void) { return 1; }