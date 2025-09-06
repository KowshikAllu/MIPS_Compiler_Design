%{
    #include <stdio.h>
    #include <stdlib.h>

    extern int yylex();
    extern int yylineno;
    void yyerror(const char *s);

    int success = 1;   // flag to track parsing success
%}

%token INT CHAR FLOAT STRING VOID RETURN INPUT OUTPUT SWITCH CASE BREAK CONTINUE DEFAULT
%token IF ELSEIF ELSE WHILE FOR
%token ID INT_NUM FLOAT_NUM STR CHARACTER
%token ADD SUBTRACT MULTIPLY DIVIDE MODULO
%token ASSIGN
%token GT LT GE LE EQ NE
%token AND OR NOT
%token BITAND BITOR XOR NEGATION
%token LEFTSHIFT RIGHTSHIFT
%token SCOL COMMA COLON
%token OF CF OC CC OS CS

%%

program:
        decl_list   { printf("✔ Program parsed successfully!\n"); }
        ;

decl_list:
        decl_list decl   { printf("Parsed declaration.\n"); }
        | decl
        ;

decl:
        type ID SCOL                     { printf("Variable declaration.\n"); }
        | type ID ASSIGN expr SCOL       { printf("Variable initialization.\n"); }
        | func_def
        ;

type:
        INT     { printf("Type: int\n"); }
        | CHAR  { printf("Type: char\n"); }
        | FLOAT { printf("Type: float\n"); }
        | STRING{ printf("Type: string\n"); }
        | VOID  { printf("Type: void\n"); }
        ;

func_def:
        type ID OC param_list_opt CC OF stmt_list CF { printf("Function definition parsed.\n"); }
        ;

param_list_opt:
        /* empty */
        | param_list
        ;

param_list:
        param_list COMMA param
        | param
        ;

param:
        type ID   { printf("Function parameter.\n"); }
        ;

stmt_list:
        stmt_list stmt
        | stmt
        ;

stmt:
        expr_stmt
        | if_stmt
        | while_stmt
        | for_stmt
        | return_stmt
        | block
        ;

expr_stmt:
        expr SCOL   { printf("Expression statement.\n"); }
        | SCOL
        ;

if_stmt:
        IF OC expr CC stmt                    { printf("If statement parsed.\n"); }
        | IF OC expr CC stmt ELSE stmt        { printf("If-Else statement parsed.\n"); }
        ;

while_stmt:
        WHILE OC expr CC stmt                 { printf("While loop parsed.\n"); }
        ;

for_stmt:
        FOR OC expr_stmt expr_stmt expr CC stmt { printf("For loop parsed.\n"); }
        ;

return_stmt:
        RETURN expr SCOL    { printf("Return statement.\n"); }
        | RETURN SCOL       { printf("Return statement (no value).\n"); }
        ;

block:
        OF stmt_list CF     { printf("Block parsed.\n"); }
        ;

expr:
        ID ASSIGN expr      { printf("Assignment.\n"); }
        | expr ADD expr     { printf("Addition.\n"); }
        | expr SUBTRACT expr{ printf("Subtraction.\n"); }
        | expr MULTIPLY expr{ printf("Multiplication.\n"); }
        | expr DIVIDE expr  { printf("Division.\n"); }
        | expr MODULO expr  { printf("Modulo.\n"); }
        | expr GT expr      { printf("Greater than comparison.\n"); }
        | expr LT expr      { printf("Less than comparison.\n"); }
        | expr GE expr      { printf("Greater-or-equal comparison.\n"); }
        | expr LE expr      { printf("Less-or-equal comparison.\n"); }
        | expr EQ expr      { printf("Equality comparison.\n"); }
        | expr NE expr      { printf("Not-equal comparison.\n"); }
        | expr AND expr     { printf("Logical AND.\n"); }
        | expr OR expr      { printf("Logical OR.\n"); }
        | OC expr CC
        | INT_NUM           { printf("Integer literal.\n"); }
        | FLOAT_NUM         { printf("Float literal.\n"); }
        | STR               { printf("String literal.\n"); }
        | CHARACTER         { printf("Character literal.\n"); }
        | ID                { printf("Identifier used.\n"); }
        ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "❌ Error: %s at line %d\n", s, yylineno);
    success = 0;
}

int main(void) {
    printf("🔎 Starting parsing...\n");
    if (yyparse() == 0 && success) {
        printf("✅ Parsing completed successfully with no errors.\n");
    } else {
        printf("⚠️ Parsing failed.\n");
    }
    return 0;
}
