%{
    #include <stdio.h>
    #include <string.h>
    int countn = 0;
%}

%option yylineno

alpha   [a-zA-Z_]
digit   [0-9]

%%

"int"                       { printf("TOKEN: INT (%s)\n", yytext); }
"char"                      { printf("TOKEN: CHAR (%s)\n", yytext); }
"float"                     { printf("TOKEN: FLOAT (%s)\n", yytext); }
"string"                    { printf("TOKEN: STRING (%s)\n", yytext); }
"void"                      { printf("TOKEN: VOID (%s)\n", yytext); }
"return"                    { printf("TOKEN: RETURN (%s)\n", yytext); }
"input"                     { printf("TOKEN: INPUT (%s)\n", yytext); }
"output"                    { printf("TOKEN: OUTPUT (%s)\n", yytext); }
"switch"                    { printf("TOKEN: SWITCH (%s)\n", yytext); }
"case"                      { printf("TOKEN: CASE (%s)\n", yytext); }
"break"                     { printf("TOKEN: BREAK (%s)\n", yytext); }
"continue"                  { printf("TOKEN: CONTINUE (%s)\n", yytext); }
"default"                   { printf("TOKEN: DEFAULT (%s)\n", yytext); }
"if"                        { printf("TOKEN: IF (%s)\n", yytext); }
"else if"                   { printf("TOKEN: ELSEIF (%s)\n", yytext); }
"else"                      { printf("TOKEN: ELSE (%s)\n", yytext); }
"while"                     { printf("TOKEN: WHILE (%s)\n", yytext); }
"for"                       { printf("TOKEN: FOR (%s)\n", yytext); }

{digit}+                    { printf("TOKEN: INT_NUM (%s)\n", yytext); }
{digit}+\.{digit}+          { printf("TOKEN: FLOAT_NUM (%s)\n", yytext); }
{alpha}({alpha}|{digit})*   { printf("TOKEN: ID (%s)\n", yytext); }

"<<"                        { printf("TOKEN: LEFTSHIFT (%s)\n", yytext); }
">>"                        { printf("TOKEN: RIGHTSHIFT (%s)\n", yytext); }

"<="                        { printf("TOKEN: LE (%s)\n", yytext); }
">="                        { printf("TOKEN: GE (%s)\n", yytext); }
"=="                        { printf("TOKEN: EQ (%s)\n", yytext); }
"!="                        { printf("TOKEN: NE (%s)\n", yytext); }
">"                         { printf("TOKEN: GT (%s)\n", yytext); }
"<"                         { printf("TOKEN: LT (%s)\n", yytext); }
"&&"                        { printf("TOKEN: AND (%s)\n", yytext); }
"||"                        { printf("TOKEN: OR (%s)\n", yytext); }

"+"                         { printf("TOKEN: ADD (%s)\n", yytext); }
"-"                         { printf("TOKEN: SUBTRACT (%s)\n", yytext); }
"/"                         { printf("TOKEN: DIVIDE (%s)\n", yytext); }
"%"                         { printf("TOKEN: MODULO (%s)\n", yytext); }
"*"                         { printf("TOKEN: MULTIPLY (%s)\n", yytext); }
"="                         { printf("TOKEN: ASSIGN (%s)\n", yytext); }

"&"                         { printf("TOKEN: BITAND (%s)\n", yytext); }
"|"                         { printf("TOKEN: BITOR (%s)\n", yytext); }
"~"                         { printf("TOKEN: NEGATION (%s)\n", yytext); }
"^"                         { printf("TOKEN: XOR (%s)\n", yytext); }

"!"                         { printf("TOKEN: NOT (%s)\n", yytext); }
";"                         { printf("TOKEN: SCOL (%s)\n", yytext); }
","                         { printf("TOKEN: COMMA (%s)\n", yytext); }
":"                         { printf("TOKEN: COLON (%s)\n", yytext); }
"{"                         { printf("TOKEN: OF (%s)\n", yytext); }
"("                         { printf("TOKEN: OC (%s)\n", yytext); }
"["                         { printf("TOKEN: OS (%s)\n", yytext); }
"}"                         { printf("TOKEN: CF (%s)\n", yytext); }
")"                         { printf("TOKEN: CC (%s)\n", yytext); }
"]"                         { printf("TOKEN: CS (%s)\n", yytext); }

\/\/.*                      { ; }
\/\*(.*\n)*.*\*\/           { ; } 
[ \t]*                      { ; }
\n                          { countn++; }

\"([^\\\"]|\\.)*\"          { printf("TOKEN: STR (%s)\n", yytext); }
\'([^\\\']|\\.)\'           { printf("TOKEN: CHARACTER (%s)\n", yytext); }

.                           { printf("UNKNOWN: %s\n", yytext); }

%%

int yywrap(void) { return 1; }