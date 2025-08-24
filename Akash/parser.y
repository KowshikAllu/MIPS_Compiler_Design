%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

int yylex(void);
void yyerror(const char *s);

typedef struct var {
    char *name;
    int isFloat;
    double value;
    struct var *next;
} Var;

Var *symtab = NULL;

int loop_break = 0;
int loop_continue = 0;

Var* lookup(char *name) {
    for (Var *v = symtab; v; v = v->next) {
        if (strcmp(v->name, name) == 0) return v;
    }
    return NULL;
}

void assign(char *name, double val, int isFloat) {
    Var *v = lookup(name);
    if (!v) {
        v = (Var*) malloc(sizeof(Var));
        v->name = strdup(name);
        v->next = symtab;
        symtab = v;
    }
    v->value = val;
    v->isFloat = isFloat;
}
%}

%union {
    int ival;
    double fval;
    char *sval;
}

%token INPUT OUTPUT RETURN FOR IF ELSE CONTINUE BREAK
%token INT FLOAT
%token <ival> INT_LITERAL
%token <fval> FLOAT_LITERAL
%token <sval> IDENTIFIER STRING
%token EQ NEQ LE GE
%type <fval> expr

%%

program : stmt_list ;

stmt_list : stmt_list stmt
          | stmt ;

stmt : decl ';'
     | assign ';'
     | io ';'
     | RETURN expr ';'        { exit((int)$2); }
     | FOR '(' assign ';' expr ';' assign ')' '{' stmt_list '}' {
            for(; $5; ) {
                loop_break = loop_continue = 0;
                yyparse(); 
                if (loop_break) break;
                if (loop_continue) { loop_continue=0; continue; }
            }
      }

     | IF '(' expr ')' '{' stmt_list '}' ELSE '{' stmt_list '}' {
            if ($3) { /* true block executed */ }
            else    { /* false block executed */ }
     }
     | CONTINUE ';'           { loop_continue = 1; return 0; }
     | BREAK ';'              { loop_break = 1; return 0; }
     ;

decl : INT IDENTIFIER          { assign($2, 0, 0); }
     | FLOAT IDENTIFIER        { assign($2, 0, 1); }
     ;

assign : IDENTIFIER '=' expr   { assign($1, $3, 1); } ;

io : OUTPUT '(' expr ')'       { printf("%g\n", $3); }
   | OUTPUT '(' STRING ')'     { 
         char *s = strdup($3);
         s[strlen(s)-1] = '\0';    // strip last quote
         printf("%s\n", s+1);      // skip first quote
     }
   | INPUT '(' IDENTIFIER ')'  {
         double x; scanf("%lf", &x); assign($3, x, 1);
     }
   ;

expr : expr '+' expr           { $$ = $1 + $3; }
     | expr '-' expr           { $$ = $1 - $3; }
     | expr '*' expr           { $$ = $1 * $3; }
     | expr '/' expr           { $$ = $1 / $3; }
     | expr '%' expr           { $$ = fmod($1, $3); }
     | '(' expr ')'            { $$ = $2; }
     | INT_LITERAL             { $$ = $1; }
     | FLOAT_LITERAL           { $$ = $1; }
     | IDENTIFIER              {
         Var *v = lookup($1);
         if (!v) { printf("Undefined var %s\n",$1); $$=0; }
         else $$=v->value;
       }
     | expr EQ expr            { $$ = ($1 == $3); }
     | expr NEQ expr           { $$ = ($1 != $3); }
     | expr '<' expr           { $$ = ($1 < $3); }
     | expr '>' expr           { $$ = ($1 > $3); }
     | expr LE expr            { $$ = ($1 <= $3); }
     | expr GE expr            { $$ = ($1 >= $3); }
     ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {
    return yyparse();
}