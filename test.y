%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex();
char* itoa(int);
int num_d(int);

int num=0;
int labelv = 1;
int temp = 1;
struct s {
    int True;
    int False;
    int next;
    int lexval;
    char code[10000];
};

#define INT_SIZE 4
#define FLOAT_SIZE 4
#define CHAR_SIZE 1

typedef struct {
    char *name;
    char *type;
    int size;
    int offset;
} symbol;

symbol symbolTable[100];
int eflag = -1;
int symbolCount = 0;
int currentOffset = 0;

void yyerror(const char *s);
int lookup(char *name);
void insertSymbol(char *name, int eflag);
void checkRedeclaration(char *name);
void updateOffset(char *type);
void clearSymbolTable();

extern FILE *yyin;
%}

%name parser

%union {
    int val;
    float fval;
    char *sval;
    char lexeme[20];
    char addr[100];
    struct s* eval;
}

%token <lexeme> VAR PLUS MINUS MOD DIV MUL INC DEC PE ME MuE DE EE GT LT GE LE NE AND OR IF ELSE WHILE INT FLOAT CHAR
%token <val> NUM
%token <fval> DECIMAL
%token <sval> ARRAY

%type <eval> start stmt stmt1 Cond1 Cond2 Comp expression compound term factor factor2 dtype value
%type <addr> declaration declarations type var_list

%left PLUS MINUS
%left MUL DIV MOD

%%

start: stmt {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $1->code);
            printf("============TAC of the given code============\n\n");

            // Add line numbers to the output
            int line_number = 1;
            char* line = strtok($$->code, "\n");
            while (line != NULL) {
                printf("%d:\t%s\n", line_number++, line);
                line = strtok(NULL, "\n");
            }
            printf("\n===========Completed============\n");
        }

stmt:   stmt1 stmt {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $1->code);
            strcat($$->code, $2->code);
        } 
        | stmt1 {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $1->code);
        }

Cond1:  Cond2 AND Cond2 {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $1->code);
            strcat($$->code, " AND ");
            strcat($$->code, $3->code);
        } 
        | Cond2 OR Cond2 {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $1->code);
            strcat($$->code, " OR ");
            strcat($$->code, $3->code);
        }
        | Cond2 {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $1->code);
        }
Cond2:  VAR Comp VAR {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $1);
            strcat($$->code, $2->code);
            strcat($$->code, $3);
        } 
        | VAR Comp NUM {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $1);
            strcat($$->code, $2->code);
            strcat($$->code, itoa($3));
        } 
        | NUM Comp VAR{
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, itoa($1));
            strcat($$->code, $2->code);
            strcat($$->code, $3);
        } 
        | NUM Comp NUM {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, itoa($1));
            strcat($$->code, $2->code);
            strcat($$->code, itoa($3));
        }
Comp:   EE {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "==");
        } 
        | GT {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, ">");
        } 
        | LT {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "<");
        } 
        | GE {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, ">=");
        } 
        | LE {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "<=");
        } 
        | NE {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "!=");
        }

stmt1:  IF '(' Cond1 ')' '{' stmt '}' {
            $$ = (struct s*)malloc(sizeof(struct s));
            $3->True = labelv;
            labelv++;
            $3->False = labelv;
            labelv++;
            $$->next = $3->False;
            $6->next = $3->False;
            strcpy($$->code, "if");
            strcat($$->code, $3->code);
            strcat($$->code, " goto Label");
            strcat($$->code, itoa($3->True));
            strcat($$->code, "\n");
            strcat($$->code, "goto Label");
            strcat($$->code, itoa($3->False));
            strcat($$->code, "\n");
            strcat($$->code, "Label");
            strcat($$->code, itoa($3->True));
            strcat($$->code, ":\n");
            strcat($$->code, $6->code);
            strcat($$->code, "Label");
            strcat($$->code, itoa($3->False));
            strcat($$->code, ":\n");
        }
        | IF '(' Cond1 ')' '{' stmt '}' ELSE '{' stmt '}' {
            $$ = (struct s*)malloc(sizeof(struct s));
            $3->True = labelv;
            labelv++;
            $3->False = labelv;
            labelv++;
            $$->next = $3->False;
            $6->next = $3->False;
            $10->next = $3->False;
            strcpy($$->code, "if ");
            strcat($$->code, $3->code);
            strcat($$->code, " goto Label");
            strcat($$->code, itoa($3->True));
            strcat($$->code, "\n");
            strcat($$->code, "goto Label");
            strcat($$->code, itoa($3->False));
            strcat($$->code, "\n");
            strcat($$->code, "Label");
            strcat($$->code, itoa($3->True));
            strcat($$->code, ":\n");
            strcat($$->code, $6->code);
            strcat($$->code, "Label");
            strcat($$->code, itoa($3->False));
            strcat($$->code, ":\n");
            strcat($$->code, $10->code);
            strcat($$->code, "Label");
            strcat($$->code, itoa(labelv));
            strcat($$->code, ":\n");
            labelv++;
        }
        | WHILE '(' Cond1 ')' '{' stmt '}' {
            $$ = (struct s*)malloc(sizeof(struct s));
            $3->True=labelv;
            labelv++;
            $3->False=labelv;
            labelv++;
            $$->next=$3->False;
            $6->next=$3->True;
            strcpy($$->code,"Label");
            strcat($$->code, itoa($3->True));
            strcat($$->code,":\n");
            strcat($$->code,"ifFalse ");
            strcat($$->code,$3->code);
            strcat($$->code," goto Label");
            strcat($$->code, itoa($3->False));
            strcat($$->code,"\n");
            strcat($$->code,$6->code);
            strcat($$->code,"goto Label");
            strcat($$->code, itoa($3->True));
            strcat($$->code,"\n");
            strcat($$->code,"Label");
            strcat($$->code, itoa($3->False));
            strcat($$->code,":\n");
        }
        | VAR compound expression ';' {   
            if (strcmp($2->code, "=") == 0) {
                $$ = (struct s*)malloc(sizeof(struct s));
                strcpy($$->code, $3->code);
                strcat($$->code, $1);
                strcat($$->code, " = ");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp-1));
                strcat($$->code, "\n");
                strcat($$->code, ">>>>>>");
                strcat($$->code, "\n");
            } else if (strcmp($2->code, "+=") == 0) {
                $$ = (struct s*)malloc(sizeof(struct s));
                strcpy($$->code, $3->code);
                strcat($$->code, "t");
                strcat($$->code, itoa(temp));
                strcat($$->code, " = ");
                strcat($$->code, $1);
                temp++;
                strcat($$->code, "\n");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp));
                strcat($$->code, " = ");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp-2));
                strcat($$->code, " + ");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp-1));
                strcat($$->code, "\n");
                strcat($$->code, $1);
                strcat($$->code, " = ");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp));
                strcat($$->code, "\n");
                temp++;

            } else if (strcmp($2->code, "-=") == 0) {
                $$ = (struct s*)malloc(sizeof(struct s));
                strcpy($$->code, $3->code);
                strcat($$->code, "t");
                strcat($$->code, itoa(temp));
                strcat($$->code, " = ");
                strcat($$->code, $1);
                temp++;
                strcat($$->code, "\n");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp));
                strcat($$->code, " = ");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp-2));
                strcat($$->code, " - ");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp-1));
                strcat($$->code, "\n");
                strcat($$->code, $1);
                strcat($$->code, " = ");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp));
                strcat($$->code, "\n");
                temp++;
            } else if (strcmp($2->code, "*=") == 0) {
                $$ = (struct s*)malloc(sizeof(struct s));
                strcpy($$->code, $3->code);
                strcat($$->code, "t");
                strcat($$->code, itoa(temp));
                strcat($$->code, " = ");
                strcat($$->code, $1);
                temp++;
                strcat($$->code, "\n");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp));
                strcat($$->code, " = ");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp-2));
                strcat($$->code, " * ");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp-1));
                strcat($$->code, "\n");
                strcat($$->code, $1);
                strcat($$->code, " = ");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp));
                strcat($$->code, "\n");
                temp++;
            } else if (strcmp($2->code, "/=") == 0) {
                $$ = (struct s*)malloc(sizeof(struct s));
                strcpy($$->code, $3->code);
                strcat($$->code, "t");
                strcat($$->code, itoa(temp));
                strcat($$->code, " = ");
                strcat($$->code, $1);
                temp++;
                strcat($$->code, "\n");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp));
                strcat($$->code, " = ");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp-2));
                strcat($$->code, " / ");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp-1));
                strcat($$->code, "\n");
                strcat($$->code, $1);
                strcat($$->code, " = ");
                strcat($$->code, "t");
                strcat($$->code, itoa(temp));
                strcat($$->code, "\n");
                temp++;
            }
            num=0;
        } 
        | VAR compound '(' expression error ';' { 
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "-----Rejected - Close parenthesis missing-----\n"); 
        }
        | VAR compound expression ')' error ';' { 
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "-----Rejected - Open parenthesis missing-----\n"); 
        }
        | expression ';' {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $1->code);
        }
        | '{' { clearSymbolTable(); } declarations stmt1 '}'
        | error ';' { 
            $$ = (struct s*)malloc(sizeof(struct s)); 
            strcpy($$->code, "-----Rejected - Invalid Format-----\n"); 
        }



declarations: 
      declarations declaration
    | {}
    ;

declaration: type var_list ';' ;

type: INT    { eflag = 0; }
    | FLOAT  { eflag = 1; }
    | CHAR   { eflag = 2; }
    ;

var_list: VAR { checkRedeclaration($1); insertSymbol($1, eflag); }
        | var_list ',' VAR { checkRedeclaration($3); insertSymbol($3, eflag); }
        | VAR '=' NUM { if(eflag!=0){ 
            printf("error: assign integer value\n");
            exit(1); 
        } 
        checkRedeclaration($1); insertSymbol($1, eflag); }
        | VAR '=' DECIMAL { 
        if(eflag==2){ 
            printf("error: assign floating value\n");
            exit(1); 
        } 
        checkRedeclaration($1); insertSymbol($1, eflag); }
        | VAR '=' '\'' VAR '\'' { if(eflag!=2){ 
            printf("error: assign character value\n");
            exit(1); 
        } 
        checkRedeclaration($1); insertSymbol($1, eflag); }
        | ARRAY {}
        ;


compound:   '=' {
                $$ = (struct s*)malloc(sizeof(struct s));
                strcpy($$->code, "=");
            }
            | PE {
                $$ = (struct s*)malloc(sizeof(struct s));
                strcpy($$->code, "+=");
            }
            | ME{
                $$ = (struct s*)malloc(sizeof(struct s));
                strcpy($$->code, "-=");
            }
            | MuE {
                $$ = (struct s*)malloc(sizeof(struct s));
                strcpy($$->code, "*=");
            }
            | DE {
                $$ = (struct s*)malloc(sizeof(struct s));
                strcpy($$->code, "/=");
            }

expression: term {
                $$ = (struct s*)malloc(sizeof(struct s));
                strcpy($$->code, $1->code);
                $$->lexval = $1->lexval;
            }
            | expression PLUS term {
                $$ = (struct s*)malloc(sizeof(struct s));
                strcpy($$->code, $1->code);
                strcat($$->code, $3->code);
                strcat($$->code, "t");
                strcat($$->code, itoa(temp));
                strcat($$->code, " = ");
                strcat($$->code, "t");
                strcat($$->code, itoa($1->lexval));
                strcat($$->code, " + ");
                strcat($$->code, "t");
                strcat($$->code, itoa($3->lexval));
                strcat($$->code, "\n");
                $$->lexval = temp;
                temp++;
            }
            | expression MINUS term {
                $$ = (struct s*)malloc(sizeof(struct s));
                strcpy($$->code, $1->code);
                strcat($$->code, $3->code);
                strcat($$->code, "t");
                strcat($$->code, itoa(temp));
                strcat($$->code, " = ");
                strcat($$->code, "t");
                strcat($$->code, itoa($1->lexval));
                strcat($$->code, " - ");
                strcat($$->code, "t");
                strcat($$->code, itoa($3->lexval));
                strcat($$->code, "\n");
                $$->lexval = temp;
                temp++;
            }

term:   factor {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $1->code);
            $$->lexval = $1->lexval;
        }
        | term MUL factor {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $1->code);
            strcat($$->code, $3->code);
            strcat($$->code, "t");
            strcat($$->code, itoa(temp));
            strcat($$->code, " = ");
            strcat($$->code, "t");
            strcat($$->code, itoa($1->lexval));
            strcat($$->code, " * ");
            strcat($$->code, "t");
            strcat($$->code, itoa($3->lexval));
            strcat($$->code, "\n");
            $$->lexval = temp;
            temp++;
        }
        | term DIV factor {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $1->code);
            strcat($$->code, $3->code);
            strcat($$->code, "t");
            strcat($$->code, itoa(temp));
            strcat($$->code, " = ");
            strcat($$->code, "t");
            strcat($$->code, itoa($1->lexval));
            strcat($$->code, " / ");
            strcat($$->code, "t");
            strcat($$->code, itoa($3->lexval));
            strcat($$->code, "\n");
            $$->lexval = temp;
            temp++;
        }
        | term MOD factor2 {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $1->code);
            strcat($$->code, $3->code);
            strcat($$->code, "t");
            strcat($$->code, itoa(temp));
            strcat($$->code, " = ");
            strcat($$->code, "t");
            strcat($$->code, itoa($1->lexval));
            strcat($$->code, " % ");
            strcat($$->code, "t");
            strcat($$->code, itoa($3->lexval));
            strcat($$->code, "\n");
            $$->lexval = temp;
            temp++;
        }

factor: value {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $1->code);
            $$->lexval = $1->lexval;
            // strcat($$->code, "\n");
        }
        | MINUS value {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "t");
            strcat($$->code, itoa(temp));
            strcat($$->code, " = ");
            strcat($$->code, "-");
            strcat($$->code, $2->code);
            // strcat($$->code, "\n");
            $$->lexval = temp;
            temp++;
        }
        | PLUS value {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "t");
            strcat($$->code, itoa(temp));
            strcat($$->code, " = ");
            strcat($$->code, $2->code);
            // strcat($$->code, "\n");
            $$->lexval = temp;
            temp++;
        }
        | VAR INC {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "t");
            strcat($$->code, itoa(temp));
            strcat($$->code, " = ");
            strcat($$->code, $1);
            strcat($$->code, "\n");
            strcat($$->code, $1);
            strcat($$->code, " = ");
            strcat($$->code, $1);
            strcat($$->code, "+");
            strcat($$->code, "1");
            strcat($$->code, "\n");
            $$->lexval = temp;
            temp++;
        }
        | VAR DEC {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "t");
            strcat($$->code, itoa(temp));
            strcat($$->code, " = ");
            strcat($$->code, $1);
            strcat($$->code, "\n");
            strcat($$->code, $1);
            strcat($$->code, " = ");
            strcat($$->code, $1);
            strcat($$->code, "-");
            strcat($$->code, "1");
            strcat($$->code, "\n");
            $$->lexval = temp;
            temp++;
        }
        | INC VAR {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "");
            strcat($$->code, $2);
            strcat($$->code, " = ");
            strcat($$->code, $2);
            strcat($$->code, "+");
            strcat($$->code, "1");
            strcat($$->code, "\n");
            strcpy($$->code, "t");
            strcat($$->code, itoa(temp));
            strcat($$->code, " = ");
            strcat($$->code, $2);
            strcat($$->code, "\n");
            $$->lexval = temp;
            temp++;
        }
        | DEC VAR {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "");
            strcat($$->code, $2);
            strcat($$->code, " = ");
            strcat($$->code, $2);
            strcat($$->code, "-");
            strcat($$->code, "1");
            strcat($$->code, "\n");
            strcpy($$->code, "t");
            strcat($$->code, itoa(temp));
            strcat($$->code, " = ");
            strcat($$->code, $2);
            strcat($$->code, "\n");
            $$->lexval = temp;
            temp++;
        }

factor2: NUM {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "t");
            strcat($$->code, itoa(temp));
            strcat($$->code, " = ");
            strcat($$->code, itoa($1));
            strcat($$->code, "\n");
            $$->lexval = temp;        
            temp++;
        } 
        | VAR {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "t");
            strcat($$->code, itoa(temp));
            strcat($$->code, " = ");
            strcat($$->code, $1);
            strcat($$->code, "\n");
            $$->lexval = temp;        
            temp++;
        } 
        | '(' expression ')' {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $2->code);
        }

value:  '(' expression ')' {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $2->code);
            $$->lexval = $2->lexval;
        }
        | dtype {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, $1->code);
            $$->lexval = $1->lexval;
        } 

dtype:  VAR {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "t");
            strcat($$->code, itoa(temp));
            strcat($$->code, " = ");
            strcat($$->code, $1);
            strcat($$->code, "\n");
            $$->lexval = temp;
            temp++;
        } 
        | NUM {
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "t");
            strcat($$->code, itoa(temp));
            strcat($$->code, " = ");
            strcat($$->code, itoa($1));
            strcat($$->code, "\n");
            $$->lexval = temp;        
            temp++;
        }
        | DECIMAL {   
            $$ = (struct s*)malloc(sizeof(struct s));
            strcpy($$->code, "t");
            strcat($$->code, itoa(temp));
            strcat($$->code, " = ");
            sprintf($$->code, "%f", $1);    // Convert float to string and store in $$
            strcat($$->code, "\n");
            $$->lexval = temp;        
            temp++;
        } 

%%

void yyerror(const char *s) {
   
}

int lookup(char *name) {
    for (int i = 0; i < symbolCount; i++) {
        if (strcmp(symbolTable[i].name, name) == 0) return i;
    }
    return -1;
}

void insertSymbol(char *name, int eflag) {
    int size;
    if (lookup(name) == -1) {
        symbolTable[symbolCount].name = strdup(name);
        char* c[10];
        if(eflag == 0){
            symbolTable[symbolCount].type = "int";
            symbolTable[symbolCount].size = INT_SIZE;
            size = INT_SIZE;
            *c = "int";
        } else if(eflag == 1){
            symbolTable[symbolCount].type = "float";
            symbolTable[symbolCount].size = FLOAT_SIZE;
            size = FLOAT_SIZE;
            *c = "float";
        } else if(eflag == 2){
            symbolTable[symbolCount].type = "char";
            symbolTable[symbolCount].size = CHAR_SIZE;
            size = CHAR_SIZE;
            *c = "char";
        }
        symbolTable[symbolCount].offset = currentOffset;
        printf("0x%04X %s %s\n", currentOffset, name, *c);
        currentOffset += size;
        symbolCount++;
    } else {
        printf("error: redeclaration of '%s'\n", name);
    }
}

void checkRedeclaration(char *name) {
    if (lookup(name) != -1) {
        printf("error: redeclaration of '%s'\n", name);
        exit(1);
    }
}

void updateOffset(char *type) {
    /* if (strcmp(type, "int") == 0)
        currentOffset += INT_SIZE;
    else if (strcmp(type, "float") == 0)
        currentOffset += FLOAT_SIZE;
    else if (strcmp(type, "char") == 0)
        currentOffset += CHAR_SIZE; */
}

void clearSymbolTable() {
    for (int i = 0; i < symbolCount; i++) {        
        // Set all struct fields to NULL or 0
        symbolTable[i].name = NULL;
        symbolTable[i].type = NULL;
        symbolTable[i].size = 0;
        symbolTable[i].offset = 0;
    }
    symbolCount = 0;
    currentOffset = 0;
}

int main(int argc, char *argv[]) {
    if (argc > 1) {
        FILE *fp = fopen(argv[1], "r");
        if (fp) {
            yyin = fp;
        } else {
            perror("Error opening file");
            return 0;
        }
    }

    yyparse();
    return 1;
}

char* itoa(int num) {
    int len = 0, temp = num, i;
    do {
        len++;
        temp /= 10;
    } while (temp != 0);
    char* str = (char*)malloc(sizeof(char) * (len + 1));
    if (!str) return NULL;
    str[len] = '\0';
    for (i = len - 1; i >= 0; i--) {
        str[i] = '0' + (num % 10);
        num /= 10;
    }
    return str;
}

int num_d(int j) {
    int c = 1;
    while(j/10) {
        c = c*10;
        j = j/10;
    }
    return c;
}