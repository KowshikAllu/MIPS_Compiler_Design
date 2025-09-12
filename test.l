%{
#include "y.tab.h"
#include <stdio.h>
#include <stdlib.h>
%}

digit [0-9]
word [a-zA-Z_]

%%

"if"                             { strcpy(yylval.lexeme, yytext); return IF;}
"else"                           { strcpy(yylval.lexeme, yytext); return ELSE;}
"while"                          { strcpy(yylval.lexeme, yytext); return WHILE;}
"int"                            { return INT; }
"float"                          { return FLOAT; }
"char"                           { return CHAR; }
{word}[a-zA-Z0-9_]*"["{digit}+"]"      { yylval.sval = strdup(yytext); return ARRAY; }
{word}({word}|{digit})*? {
    strcpy(yylval.lexeme, yytext);
    return VAR;
}
{digit}+ {
    yylval.val = atoi(yytext);
    return NUM;
}
{digit}+\.{digit}*               { yylval.fval = atof(yytext); return DECIMAL; }
"+"                              { strcpy(yylval.lexeme, yytext); return PLUS; }
"-"                              { strcpy(yylval.lexeme, yytext); return MINUS; }
"*"                              { strcpy(yylval.lexeme, yytext); return MUL; }
"/"                              { strcpy(yylval.lexeme, yytext); return DIV; }
"%"                              { strcpy(yylval.lexeme, yytext); return MOD; }
"++"                             { strcpy(yylval.lexeme, yytext); return INC; }
"--"                             { strcpy(yylval.lexeme, yytext); return DEC; }
"+="                             { strcpy(yylval.lexeme, yytext); return PE; }
"-="                             { strcpy(yylval.lexeme, yytext); return ME; }
"*="                             { strcpy(yylval.lexeme, yytext); return MuE; }
"/="                             { strcpy(yylval.lexeme, yytext); return DE; }
"=="                             { strcpy(yylval.lexeme, yytext); return EE; }
"<"                              { strcpy(yylval.lexeme, yytext); return LT; }
">"                              { strcpy(yylval.lexeme, yytext); return GT; }
"<="                             { strcpy(yylval.lexeme, yytext); return LE; }
">="                             { strcpy(yylval.lexeme, yytext); return GE; }
"!="                             { strcpy(yylval.lexeme, yytext); return NE; }
"&&"                             { strcpy(yylval.lexeme, yytext); return AND; }
"||"                             { strcpy(yylval.lexeme, yytext); return OR; }
[ \t\n]+                         ;  
.                                { return yytext[0]; }

%%

int yywrap() {
    return 1;
}