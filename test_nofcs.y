%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <ctype.h>
    #include <vector>
    #include <string.h>
    #include <queue>
    #include <set>

    #define add_tac($$, $1, $2, $3) {strcpy($$.type, $1.type);\
        sprintf($$.lexeme, get_temp().c_str());\
        string lt=string($1.type);\
        string rt=string($3.type);\
        if((lt == "CHAR" && rt == "INT") || (rt == "CHAR" && lt == "INT")){\
            strcpy($$.type, "INT");\
        }\
        else if((lt == "FLOAT" && rt == "INT") || (rt == "FLOAT" && lt == "INT")){\
            strcpy($$.type, "FLOAT");\
        }\
        else if((lt == "FLOAT" && rt == "FLOAT") || (lt == "INT" && rt == "INT") || (lt == "CHAR" && rt == "CHAR")){\
            strcpy($$.type, $1.type);\
        }\
        else{\
            sem_errors.push_back("Cannot convert between CHAR and FLOAT in line : " + to_string(countn+1));\
        }}
    
    #include <iostream>
    #include <string>
    #include <unordered_map>
    #include<map>
    #include <stack>
    #include<algorithm>
    #include<fstream>
    #include <iomanip>

    using namespace std;

    void yyerror(const char *s);
    int yylex();
    int yywrap();
    int yytext();

    bool check_declaration(string variable);
    bool multiple_declaration(string variable);
    bool is_reserved_word(string id);
    bool type_check(string type1, string type2);
    bool check_type(string l, string r);
    string get_temp();

    queue<string> free_temp;
    set<string> const_temps;
    void PrintStack(stack<int> s);
    void print_symbol_table();

    struct var_info {
        string data_type;
        int scope;
        int size;   // for arrays
        int isArray;
        int line_number; 
    };

    vector<string> tac;
    map<string, string> temp_map;

    int variable_count = 0;
    int label_counter = 0;

    vector<string> sem_errors;

    int temp_index;
    int temp_label;

    stack<int> loop_continue, loop_break;
    stack<int> scope_history;
    int scope_counter = 0;

    // for array declaration with initialization
    string curr_array;
    int arr_index=0;

    extern int countn;

    struct func_info{
        string return_type;
        int num_params;
        vector<string> param_types;
        unordered_map<string, struct var_info> symbol_table;
    };

    unordered_map<string, struct func_info> func_table;
    string curr_func_name = "main";

    vector<string> reserved = {"int", "float", "char", "string", "void", "if", "elif", "else", "for", "while", "break", "continue", "main", "input", "output"};

%}

%union{
    struct node { 
        char lexeme[100];
        int line_number;
        char type[100];
        char if_body[5];
        char elif_body[5];
		char else_body[5];
        char loop_body[5];
        char parentNext[5];
        char id[5];
        char temp[5];
        int nParams;
    } node;
}

%token <node> INT CHAR FLOAT STRING INT_NUM FLOAT_NUM ID LEFTSHIFT RIGHTSHIFT LE GE EQ NE GT LT AND OR NOT ADD SUBTRACT DIVIDE MULTIPLY MODULO BITAND BITOR NEGATION XOR STR CHARACTER CC OC CS OS CF OF COMMA SCOL OUTPUT INPUT BREAK IF ELIF ELSE WHILE FOR CONTINUE

%type <node> Program stmt_list stmt declaration data_type expr primary_expr unary_expr unary_op const assign if_stmt elif_stmt else_stmt while_loop_stmt for_loop_stmt postfix_expr

%right ASSIGN
%left OR
%left AND
%left BITOR
%left XOR
%left BITAND
%left EQ NE
%left LE GE LT GT
%left LEFTSHIFT RIGHTSHIFT
%left ADD SUBTRACT
%left MULTIPLY DIVIDE MODULO
%left NEGATION

%%

Program         :       stmt_list {}

stmt_list       :       stmt stmt_list
                        |
                        ;
                
stmt            :       declaration
                        |   assign SCOL
                        |   expr SCOL
                        |   if_stmt
                        |   while_loop_stmt
                        |   for_loop_stmt
                        |   BREAK SCOL {
                                if(!loop_break.empty()){
                                    tac.push_back("GOTO #L" + to_string(loop_break.top()));
                                }
                            }
                        |   CONTINUE SCOL {
                                if(!loop_continue.empty()){
                                    tac.push_back("GOTO #L" + to_string(loop_continue.top()));
                                }
                            }
                        |   INPUT OC ID CC SCOL {
                                check_declaration($3.lexeme);
                                tac.push_back("input " + string($3.lexeme) + " " + func_table[curr_func_name].symbol_table[string($3.lexeme)].data_type);
                                // check_scope(string($3.lexeme));
                            }
                        |   INPUT OC ID OS expr CS CC SCOL {
                                check_declaration($3.lexeme);
                                string temp = get_temp();
                                tac.push_back("input " + temp + " " + func_table[curr_func_name].symbol_table[string($3.lexeme)].data_type);
                                tac.push_back(string($3.lexeme) + " [ " + string($5.lexeme) + " ] = " + temp + " " + func_table[curr_func_name].symbol_table[string($3.lexeme)].data_type);
                                free_temp.push(temp);
                                // check_scope(string($3.lexeme));
                            }
                        |   OUTPUT OC expr CC SCOL {
                                cout << "output expr" << endl;
                                tac.push_back("output " + string($3.lexeme) + " " + string($3.type));
                            }
                        |   OUTPUT OC STR CC SCOL {
                                cout << "output expr2" << endl;
                                tac.push_back("output " + string($3.lexeme) + " STR");
                            }
                        ;

declaration     :       data_type ID SCOL { 
                            is_reserved_word(string($2.lexeme));
                            if(multiple_declaration(string($2.lexeme))){
                                // check_scope(string($2.lexeme));
                            };
                            tac.push_back("- " + string($1.type) + " " + string($2.lexeme));
                            func_table[curr_func_name].symbol_table[string($2.lexeme)] = { string($1.type), scope_counter, 0, 0, countn+1 };
                        }
                        |   STRING ID ASSIGN STR SCOL {
                                is_reserved_word(string($2.lexeme));
                                multiple_declaration(string($2.lexeme));
                                tac.push_back("- STR " + string($2.lexeme));
                                tac.push_back(string($2.lexeme) + " = " + string($4.lexeme) + " STR");
                                func_table[curr_func_name].symbol_table[string($2.lexeme)] = { "STR", scope_counter, string($4.lexeme).length(), 0, countn+1 };
                            }
                        |   data_type ID ASSIGN expr SCOL {
                                is_reserved_word(string($2.lexeme));
                                multiple_declaration(string($2.lexeme));
                                check_type(string($1.type), string($4.type));
                                tac.push_back("- " + string($1.type) + " " + string($2.lexeme));
                                tac.push_back(string($2.lexeme) + " = " + string($4.lexeme) + " " + string($1.type));
                                func_table[curr_func_name].symbol_table[string($2.lexeme)] = { string($1.type), scope_counter, 0, 0, countn+1 };

                                if(const_temps.find(string($4.lexeme)) == const_temps.end() && $4.lexeme[0] == '@') free_temp.push(string($4.lexeme));
                            }
                        |   data_type ID OS INT_NUM CS SCOL {
                                is_reserved_word(string($2.lexeme));
                                multiple_declaration(string($2.lexeme));
                                tac.push_back("- " + string($1.type) + " " + string($2.lexeme) + " [ " + string($4.lexeme) + " ] ");
                                func_table[curr_func_name].symbol_table[string($2.lexeme)] = { string($1.type), scope_counter, stoi(string($4.lexeme)), 1, countn+1 };
                            }
                        |   data_type ID OS INT_NUM CS ASSIGN {
                                is_reserved_word(string($2.lexeme));
                                multiple_declaration(string($2.lexeme));
                                tac.push_back("- " + string($1.type) + " " + string($2.lexeme) + " [ " + string($4.lexeme) + " ] ");
                                func_table[curr_func_name].symbol_table[string($2.lexeme)] = { string($1.type), scope_counter, stoi(string($4.lexeme)), 1, countn+1 };
                                curr_array = string($2.lexeme);
                            } OF arr_values CF SCOL // array size must be a positive integer 
                        ;

arr_values      :       const {
                            check_type(func_table[curr_func_name].symbol_table[curr_array].data_type, string($1.type));
                            tac.push_back(curr_array + " [ " + to_string(arr_index++) + " ] = " + string($1.lexeme) + " " + func_table[curr_func_name].symbol_table[curr_array].data_type);
                            if(arr_index > func_table[curr_func_name].symbol_table[curr_array].size){
                                sem_errors.push_back("Line no: " + to_string(func_table[curr_func_name].symbol_table[curr_array].line_number) + "error: too many initializers for ‘array [" + to_string(func_table[curr_func_name].symbol_table[curr_array].size) + "]’");
                            }
                        } COMMA arr_values
                        |   const {
                                check_type(func_table[curr_func_name].symbol_table[curr_array].data_type, string($1.type));
                                tac.push_back(curr_array + " [ " + to_string(arr_index++) + " ] = " + string($1.lexeme) + " " + func_table[curr_func_name].symbol_table[curr_array].data_type);
                                if(arr_index > func_table[curr_func_name].symbol_table[curr_array].size){
                                    sem_errors.push_back("Line no: " + to_string(func_table[curr_func_name].symbol_table[curr_array].line_number) + "error: too many initializers for ‘array [" + to_string(func_table[curr_func_name].symbol_table[curr_array].size) + "]’");
                                }
                                arr_index=0;
                            }
                        ;

data_type       :       INT { strcpy($$.type, "INT"); }
                        |   CHAR { strcpy($$.type, "CHAR"); }
                        |   FLOAT { strcpy($$.type, "FLOAT"); }
                        ;

expr            :       expr ADD expr { 
                            add_tac($$, $1, $2, $3)
                            tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($2.lexeme) + " " + string($3.lexeme) + " " + string($$.type));
                            if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                            if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
                        }
                        |   expr SUBTRACT expr { 
                                add_tac($$, $1, $2, $3)
                                tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($2.lexeme) + " " + string($3.lexeme) + " " + string($$.type));
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
                            }
                        |   expr MULTIPLY expr {
                                add_tac($$, $1, $2, $3)
                                string t0 = get_temp();
                                string t1 = get_temp();
                                string t2 = get_temp();
                                string a = string($$.lexeme);
                                string b = string($1.lexeme);
                                string c = string($3.lexeme);
                                string dtype = string($$.type);
                                
                                tac.push_back(a + " = 0 " + dtype);
                                tac.push_back(t0 + " = 0 " + dtype);
                                tac.push_back(t2 + " = 1 " + dtype);
                                tac.push_back("#L" + to_string(++label_counter) + ":");
                                tac.push_back(t1 + " = " + t0 + " < " + c +  "  " + dtype);
                                tac.push_back("if " + t1 + " GOTO " + "#L" + to_string(label_counter+1) + " else GOTO " + "#L" + to_string(label_counter+2));
                                tac.push_back("#L" + to_string(++label_counter) + ":");
                                tac.push_back(a + " = " + a + " + " + b +  "  " + dtype);
                                tac.push_back(t0 + " = " + t0 + " + " + t2 +  "  " + dtype);
                                tac.push_back("GOTO #L" + to_string(label_counter-1));
                                tac.push_back("#L" + to_string(++label_counter) + ":");

                                free_temp.push(t0);
                                free_temp.push(t1);
                                free_temp.push(t2);
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));

                                label_counter++;
                            }
                        |   expr DIVIDE expr {
                                add_tac($$, $1, $2, $3)
                                string t0 = get_temp();
                                string t1 = get_temp();
                                string t2 = get_temp();
                                string a = string($$.lexeme);
                                string b = string($1.lexeme);
                                string c = string($3.lexeme);
                                string dtype = string($$.type);
                                
                                tac.push_back(a + " = 0 " + dtype);
                                tac.push_back(t0 + " = " + b + " " + dtype);
                                tac.push_back(t2 + " = 1 " + dtype);
                                tac.push_back("#L" + to_string(++label_counter) + ":");
                                tac.push_back(t1 + " = " + t0 + " >= " + c +  "  " + dtype);
                                tac.push_back("if " + t1 + " GOTO " + "#L" + to_string(label_counter+1) + " else GOTO " + "#L" + to_string(label_counter+2));
                                tac.push_back("#L" + to_string(++label_counter) + ":");
                                tac.push_back(a + " = " + a + " + " + t2 +  "  " + dtype);
                                tac.push_back(t0 + " = " + t0 + " - " + c +  "  " + dtype);
                                tac.push_back("GOTO #L" + to_string(label_counter-1));
                                tac.push_back("#L" + to_string(++label_counter) + ":");

                                free_temp.push(t0);
                                free_temp.push(t1);
                                free_temp.push(t2);
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));

                                label_counter++;
                            }
                        |   expr LE expr {
                                add_tac($$, $1, $2, $3)
                                tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($2.lexeme) + " " + string($3.lexeme) + " " + string($$.type));
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
                            }
                        |   expr GE expr {
                                add_tac($$, $1, $2, $3)
                                tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($2.lexeme) + " " + string($3.lexeme) + " " + string($$.type));
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
                            }
                        |   expr LT expr {
                                add_tac($$, $1, $2, $3)
                                tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($2.lexeme) + " " + string($3.lexeme) + " " + string($$.type));
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
                            }
                        |   expr GT expr {
                                add_tac($$, $1, $2, $3)
                                tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($2.lexeme) + " " + string($3.lexeme) + " " + string($$.type));
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
                            }
                        |   expr EQ expr {
                                add_tac($$, $1, $2, $3)
                                tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($2.lexeme) + " " + string($3.lexeme) + " " + string($$.type));
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
                            }
                        |   expr NE expr {
                                add_tac($$, $1, $2, $3)
                                string temp = get_temp();
                                tac.push_back(temp + " = " + string($1.lexeme) + " == " + string($3.lexeme) + " " + string($$.type));
                                tac.push_back(string($$.lexeme) + " = ~ " + temp + " " + string($$.type)); 

                                free_temp.push(temp);
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
                            }
                        |   expr AND expr {
                                add_tac($$, $1, $2, $3)
                                string l0 = "#L" + to_string(++label_counter);
                                string l1 = "#L" + to_string(++label_counter);
                                string l2 = "#L" + to_string(++label_counter);
                                string l3 = "#L" + to_string(++label_counter);
                                string dtype = string($$.type);

                                tac.push_back("if " + string($1.lexeme) + " GOTO " + l3 + " else GOTO " + l1);
                                tac.push_back(l3 + ":");
                                tac.push_back("if " + string($3.lexeme) + " GOTO " + l0 + " else GOTO " + l1);
                                tac.push_back(l0 + ":");
                                tac.push_back(string($$.lexeme) + " = 1 " + dtype);
                                tac.push_back("GOTO " + l2);
                                tac.push_back(l1 + ":");
                                tac.push_back(string($$.lexeme) + " = 0 " + dtype);
                                tac.push_back(l2 + ":");

                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));

                                label_counter++;
                            }
                        |   expr OR expr {
                                add_tac($$, $1, $2, $3)
                                string l0 = "#L" + to_string(++label_counter);
                                string l1 = "#L" + to_string(++label_counter);
                                string l2 = "#L" + to_string(++label_counter);
                                string l3 = "#L" + to_string(++label_counter);
                                string dtype = string($$.type);

                                tac.push_back("if " + string($1.lexeme) + " GOTO " + l0 + " else GOTO " + l3);
                                tac.push_back(l3 + ":");
                                tac.push_back("if " + string($3.lexeme) + " GOTO " + l0 + " else GOTO " + l1);
                                tac.push_back(l0 + ":");
                                tac.push_back(string($$.lexeme) + " = 1 " + dtype);
                                tac.push_back("GOTO " + l2);
                                tac.push_back(l1 + ":");
                                tac.push_back(string($$.lexeme) + " = 0 " + dtype);
                                tac.push_back(l2 + ":");

                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));

                                label_counter++;
                            }
                        |   expr MODULO expr {
                                add_tac($$, $1, $2, $3)
                                string t0 = get_temp();
                                string t1 = get_temp();
                                string t2 = get_temp();
                                string a = string($$.lexeme);
                                string b = string($1.lexeme);
                                string c = string($3.lexeme);
                                string dtype = string($$.type);
                                
                                tac.push_back(a + " = 0 " + dtype);
                                tac.push_back(t0 + " = " + b + " " + dtype);
                                tac.push_back(t2 + " = 1 " + dtype);
                                tac.push_back("#L" + to_string(++label_counter) + ":");
                                tac.push_back(t1 + " = " + t0 + " >= " + c +  "  " + dtype);
                                tac.push_back("if " + t1 + " GOTO " + "#L" + to_string(label_counter+1) + " else GOTO " + "#L" + to_string(label_counter+2));
                                tac.push_back("#L" + to_string(++label_counter) + ":");
                                tac.push_back(t0 + " = " + t0 + " - " + c +  "  " + dtype);
                                tac.push_back("GOTO #L" + to_string(label_counter-1));
                                tac.push_back("#L" + to_string(++label_counter) + ":");
                                tac.push_back(a + " = " + t0 +  "  " + dtype);

                                free_temp.push(t0);
                                free_temp.push(t1);
                                free_temp.push(t2);
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));

                                label_counter++;
                            }
                        |   expr BITAND expr {
                                add_tac($$, $1, $2, $3)
                                tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($2.lexeme) + " " + string($3.lexeme) + " " + string($$.type));
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
                            }
                        |   expr BITOR expr {
                                add_tac($$, $1, $2, $3)
                                tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($2.lexeme) + " " + string($3.lexeme) + " " + string($$.type));
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
                            }
                        |   expr XOR expr {
                                add_tac($$, $1, $2, $3)
                                string a = string($$.lexeme);
                                string b = string($1.lexeme);
                                string b_= get_temp();
                                string c = string($3.lexeme);
                                string c_= get_temp();

                                tac.push_back(b_ + " = ~ " + b + " " + string($1.type));
                                tac.push_back(c_ + " = ~ " + c + " " + string($3.type));
                                string t1 = get_temp();
                                string t2 = get_temp();
                                tac.push_back(t1 + " = " + b + " & " + c_ + " " + string($$.type));
                                tac.push_back(t2 + " = " + b_ + " & " + c + " " + string($$.type));
                                tac.push_back(a + " = " + t1 + " | " + t2 + " " + string($$.type));

                                free_temp.push(b_);
                                free_temp.push(c_);
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));

                                label_counter++;
                            }
                        |   expr LEFTSHIFT expr {
                                add_tac($$, $1, $2, $3)
                                string d = string($3.lexeme);
                                string t3 = get_temp();
                                string t4 = get_temp();
                                string l0 = "#L" + to_string(++label_counter);
                                string l1 = "#L" + to_string(++label_counter);
                                string l2 = "#L" + to_string(++label_counter);

                                string t0 = get_temp();
                                string t1 = get_temp();
                                string t2 = get_temp();
                                string a = string($$.lexeme);
                                string b = string($1.lexeme);
                                string c = get_temp();
                                tac.push_back(c + " = 2 INT");
                                string dtype = string($$.type);
                                
                                tac.push_back(t3 + " = 0 INT");
                                tac.push_back(l2 + ":");
                                tac.push_back(t4 + " = " + t3 + " < " + d + " INT");
                                tac.push_back("\nif " + t4 + " GOTO " + l0 + " else GOTO " + l1);
                                tac.push_back(l0 + ":");
                                tac.push_back(a + " = 0 " + dtype);
                                tac.push_back(t0 + " = 0 " + dtype);
                                tac.push_back(t2 + " = 1 " + dtype);
                                tac.push_back("#L" + to_string(++label_counter) + ":");
                                tac.push_back(t1 + " = " + t0 + " < " + c +  "  " + dtype);
                                tac.push_back("if " + t1 + " GOTO " + "#L" + to_string(label_counter+1) + " else GOTO " + "#L" + to_string(label_counter+2));
                                tac.push_back("#L" + to_string(++label_counter) + ":");
                                tac.push_back(a + " = " + a + " + " + b +  "  " + dtype);
                                tac.push_back(t0 + " = " + t0 + " + " + t2 +  "  " + dtype);
                                tac.push_back("GOTO #L" + to_string(label_counter-1));
                                tac.push_back("#L" + to_string(++label_counter) + ":");
                                tac.push_back("GOTO " + l2);
                                tac.push_back(l1 + ":");

                                free_temp.push(t0);
                                free_temp.push(t1);
                                free_temp.push(t2);
                                free_temp.push(t3);
                                free_temp.push(t4);
                                free_temp.push(c);
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));

                                label_counter++;
                            }
                        |   expr RIGHTSHIFT expr {
                                add_tac($$, $1, $2, $3)
                                string d = string($3.lexeme);
                                string t3 = get_temp();
                                string t4 = get_temp();
                                string l0 = "#L" + to_string(++label_counter);
                                string l1 = "#L" + to_string(++label_counter);
                                string l2 = "#L" + to_string(++label_counter);

                                string t0 = get_temp();
                                string t1 = get_temp();
                                string t2 = get_temp();
                                string a = string($$.lexeme);
                                string b = string($1.lexeme);
                                string c = get_temp();
                                tac.push_back(c + " = 2 INT");
                                string dtype = string($$.type);
                                
                                tac.push_back(t3 + " = 0 INT");
                                tac.push_back(l2 + ":");
                                tac.push_back(t4 + " = " + t3 + " < " + d + " INT");
                                tac.push_back("\nif " + t4 + " GOTO " + l0 + " else GOTO " + l1);
                                tac.push_back(l0 + ":");
                                tac.push_back(a + " = 0 " + dtype);
                                tac.push_back(t0 + " = " + b + " " + dtype);
                                tac.push_back(t2 + " = 1 " + dtype);
                                tac.push_back("#L" + to_string(++label_counter) + ":");
                                tac.push_back(t1 + " = " + t0 + " >= " + c +  "  " + dtype);
                                tac.push_back("if " + t1 + " GOTO " + "#L" + to_string(label_counter+1) + " else GOTO " + "#L" + to_string(label_counter+2));
                                tac.push_back("#L" + to_string(++label_counter) + ":");
                                tac.push_back(a + " = " + a + " + " + t2 +  "  " + dtype);
                                tac.push_back(t0 + " = " + t0 + " - " + c +  "  " + dtype);
                                tac.push_back("GOTO #L" + to_string(label_counter-1));
                                tac.push_back("#L" + to_string(++label_counter) + ":");
                                tac.push_back("GOTO " + l2);
                                tac.push_back(l1 + ":");

                                free_temp.push(t0);
                                free_temp.push(t1);
                                free_temp.push(t2);
                                free_temp.push(t3);
                                free_temp.push(t4);
                                free_temp.push(c);
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));

                                label_counter++;
                            }
                        |   unary_expr {
                                strcpy($$.type, $1.type);
                                strcpy($$.type, $1.type);
                                sprintf($$.lexeme, "%s", $1.lexeme);
                            }
                        |   primary_expr {
                                strcpy($$.type, $1.type);
                                strcpy($$.type, $1.type);
                                strcpy($$.lexeme, $1.lexeme);
                            }
                        |   postfix_expr {
                                strcpy($$.type, $1.type);
                                sprintf($$.lexeme, "%s", $1.lexeme);
                            }

postfix_expr    :       ID OS expr CS {
                            if(check_declaration(string($1.lexeme)) && func_table[curr_func_name].symbol_table[string($1.lexeme)].isArray == 0) { 
                                sem_errors.push_back("Variable is not an array"); 
                            }
                            // check_scope(string($1.lexeme));
                            strcpy($$.type, func_table[curr_func_name].symbol_table[string($1.lexeme)].data_type.c_str());
                            sprintf($$.lexeme, get_temp().c_str());
                            tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " [ " + string($3.lexeme) + " ] " + string($$.type));
                            
                            if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
                        }
                        ;
                    
unary_expr      :       unary_op primary_expr {
                            strcpy($$.type, $2.type);
                            sprintf($$.lexeme, get_temp().c_str());
                            if(string($1.lexeme) == "~" || string($1.lexeme) == "-"){
                                tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($2.lexeme) + " " + string($$.type));
                            }
                            else if(string($1.lexeme) == "+"){
                                tac.push_back(string($$.lexeme) + " = " + string($2.lexeme) + " " + string($$.type));
                            }
                            else{
                                tac.push_back(string($$.lexeme) + " = ~ " + string($2.lexeme) + " " + string($$.type));
                            }

                            if(const_temps.find(string($2.lexeme)) == const_temps.end() && $2.lexeme[0] == '@') free_temp.push(string($2.lexeme));
                        }
                        ;

primary_expr    :       ID {
                            check_declaration(string($1.lexeme));
                            // check_scope(string($1.lexeme));
                            strcpy($$.type, func_table[curr_func_name].symbol_table[string($1.lexeme)].data_type.c_str());
                            strcpy($$.lexeme, $1.lexeme);
                        }
                        |   const {
                                strcpy($$.type, $1.type);

                                string t=get_temp();
                                sprintf($$.lexeme, t.c_str());
                                tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($$.type)); 
                                temp_map[string($1.lexeme)] = string($$.lexeme);

                                const_temps.insert(t);
                                // if(temp_map[string($1.lexeme)] == ""){
                                //     string t=get_temp();
                                //     sprintf($$.lexeme, t.c_str());
                                //     tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($$.type)); 
                                //     temp_map[string($1.lexeme)] = string($$.lexeme);

                                //     const_temps.insert(t);
                                // }
                                // else{
                                //     //tac.push_back(temp_map[string($1.lexeme)] + " = " + string($1.lexeme) + " " + string($$.type)); 
                                //     strcpy($$.lexeme, temp_map[string($1.lexeme)].c_str());
                                // }
                            }
                        |   OC expr CC {
                                strcpy($$.type, $2.type);
                                strcpy($$.lexeme, $2.lexeme);
                            }
                        ;

unary_op        :       ADD 
                        | SUBTRACT 
                        | NOT
                        | NEGATION
                        ;

const           :       INT_NUM {
                            strcpy($$.type, "INT");
                            strcpy($$.lexeme, $1.lexeme);
                        }
                        | FLOAT_NUM {
                            strcpy($$.type, "FLOAT");
                            strcpy($$.lexeme, $1.lexeme);
                        }
                        | CHARACTER {
                            strcpy($$.type, "CHAR");
                            strcpy($$.lexeme, $1.lexeme);
                        }
                        ;

assign          :       ID ASSIGN expr {
                            check_type(func_table[curr_func_name].symbol_table[string($1.lexeme)].data_type, string($3.type));
                            check_declaration(string($1.lexeme));
                            // check_scope(string($1.lexeme));
                            tac.push_back(string($1.lexeme) + " = " + string($3.lexeme) + " " + func_table[curr_func_name].symbol_table[string($1.lexeme)].data_type);

                            if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
                        }
                        |   ID OS expr CS ASSIGN expr {
                                check_type(func_table[curr_func_name].symbol_table[string($1.lexeme)].data_type, string($6.type));
                                if(check_declaration(string($1.lexeme)) && func_table[curr_func_name].symbol_table[string($1.lexeme)].isArray == 0) { 
                                    sem_errors.push_back("Line no " + to_string(countn+1) + " : Variable is not an array"); 
                                }
                                // check_scope(string($1.lexeme));
                                tac.push_back(string($1.lexeme) + " [ " + string($3.lexeme) + " ] = " + string($6.lexeme) + " " + func_table[curr_func_name].symbol_table[string($1.lexeme)].data_type);

                                if(const_temps.find(string($6.lexeme)) == const_temps.end() && $6.lexeme[0] == '@') free_temp.push(string($6.lexeme));
                            }

if_stmt         :       IF {
                            sprintf($1.parentNext, "#L%d", label_counter++);
                        } OC expr CC { 
                            tac.push_back("if " + string($4.lexeme) + " GOTO #L" + to_string(label_counter) + " else GOTO #L" + to_string(label_counter+1));
                            sprintf($4.if_body, "#L%d", label_counter++);
                            sprintf($4.else_body, "#L%d", label_counter++); 
                            tac.push_back(string($4.if_body) + ":");

                            if(const_temps.find(string($4.lexeme)) == const_temps.end() && $4.lexeme[0] == '@') free_temp.push(string($4.lexeme));
                        } OF {
                            scope_history.push(++scope_counter);  
                        } stmt_list CF {  
                            scope_history.pop(); 
                            --scope_counter;
                            tac.push_back("GOTO " + string($1.parentNext));
                            tac.push_back(string($4.else_body) + ":");
                        } elif_stmt else_stmt {   
                            tac.push_back(string($1.parentNext) + ":");
                        }
                        ;

elif_stmt       :       ELIF {
                            string str = tac[tac.size() - 2].substr(5);
                            char* hold = const_cast<char*>(str.c_str());
                            sprintf($1.parentNext, "%s", hold);
                        } OC expr CC {
                            tac.push_back("if " + string($4.lexeme) + " GOTO #L" + to_string(label_counter) + " else GOTO #L" + to_string(label_counter+1));
                            sprintf($4.if_body, "#L%d", label_counter++);
                            sprintf($4.else_body, "#L%d", label_counter++); 
                            tac.push_back(string($4.if_body) + ":");

                            if(const_temps.find(string($4.lexeme)) == const_temps.end() && $4.lexeme[0] == '@') free_temp.push(string($4.lexeme));
                        } OF {
                            scope_history.push(++scope_counter);
                        } stmt_list CF {
                            scope_history.pop();
                            --scope_counter;
                            tac.push_back("GOTO " + string($1.parentNext));
                            tac.push_back(string($4.else_body) + ":");
                        } elif_stmt  
                        |
                        ;

else_stmt       :       ELSE OF {
                            scope_history.push(++scope_counter);
                        } stmt_list CF {
                            scope_history.pop(); --scope_counter;
                        }
                        |
                        ;

while_loop_stmt :       WHILE {
                            sprintf($1.loop_body, "#L%d", label_counter); 
                            loop_continue.push(label_counter++);
                            tac.push_back("\n" + string($1.loop_body) + ":");
                        } OC expr CC {
                            sprintf($4.if_body, "#L%d", label_counter++); 

                            loop_break.push(label_counter);
                            sprintf($4.else_body, "#L%d", label_counter++); 

                            tac.push_back("\nif " + string($4.lexeme) + " GOTO " + string($4.if_body) + " else GOTO " + string($4.else_body));
                            tac.push_back("\n" + string($4.if_body) + ":");

                            if(const_temps.find(string($4.lexeme)) == const_temps.end() && $4.lexeme[0] == '@') free_temp.push(string($4.lexeme));
                            
                        } OF {
                            scope_history.push(++scope_counter);
                        } stmt_list CF {
                            scope_history.pop();
                            --scope_counter;
                            tac.push_back("GOTO " + string($1.loop_body));
                            tac.push_back("\n" + string($4.else_body) + ":");
                            loop_continue.pop();
                            loop_break.pop();
                        }

for_loop_stmt   :       FOR OC assign SCOL {
                            sprintf($1.loop_body, "#L%d", label_counter++); 
                            tac.push_back("\n" + string($1.loop_body) + ":");
                        } expr SCOL {  
                            sprintf($6.if_body, "#L%d", label_counter++); 

                            loop_break.push(label_counter);
                            sprintf($6.else_body, "#L%d", label_counter++); 

                            tac.push_back("\nif " + string($6.lexeme) + " GOTO " + string($6.if_body) + " else GOTO " + string($6.else_body));

                            sprintf($6.loop_body, "#L%d", label_counter); 
                            loop_continue.push(label_counter++);
                            tac.push_back("\n" + string($6.loop_body) + ":");

                            if(const_temps.find(string($6.lexeme)) == const_temps.end() && $6.lexeme[0] == '@') free_temp.push(string($6.lexeme));
                        } assign CC {
                            tac.push_back("GOTO " + string($1.loop_body));
                            tac.push_back("\n" + string($6.if_body) + ":");
                        } OF {
                            scope_history.push(++scope_counter);
                        } stmt_list CF {
                            scope_history.pop();
                            --scope_counter;
                            tac.push_back("GOTO " + string($6.loop_body));
                            tac.push_back("\n" + string($6.else_body) + ":");
                            loop_continue.pop();
                            loop_break.pop();
                        }

%%

int main(int argc, char *argv[]) {
    yyparse();

    // Print all semantic errors, if any
    for (auto &item : sem_errors)
        cout << item << endl;

    if(sem_errors.size() > 0) 
        exit(0); 
        
    for(auto x: tac) 
        cout << x << endl;

    // Dump symbol table separately
    print_symbol_table();

    return 0;
}

bool check_declaration(string variable) {
    if(func_table[curr_func_name].symbol_table.find(variable) == func_table[curr_func_name].symbol_table.end()){
        sem_errors.push_back("Variable not declared in line " + to_string(countn+1) + " before usage.");
        return false;
    }
    return true;
}

bool multiple_declaration(string variable) {
    if(!(func_table[curr_func_name].symbol_table.find(variable) == func_table[curr_func_name].symbol_table.end())){
        sem_errors.push_back("redeclaration of '" + variable + "' in line " + to_string(countn+1));
        return true;
    }
    return false;
}

bool check_type(string l, string r) {
    if(r == "FLOAT" && l == "CHAR"){
        sem_errors.push_back("Cannot convert type FLOAT to CHAR in line " + to_string(countn+1));
        return false;
    }
    if(l == "FLOAT" && r == "CHAR"){
        sem_errors.push_back("Cannot convert typr CHAR to FLOAT in line " + to_string(countn+1));
        return false;
    }
    return true;
}

bool is_reserved_word(string id) {
    for(auto &item: id){
        item = tolower(item);
    }
    auto iterator = find(reserved.begin(), reserved.end(), id);
    if(iterator != reserved.end()){
        sem_errors.push_back("usage of reserved keyword '" + id + "' in line " + to_string(countn+1));
        return true;
    }
    return false;
}

bool type_check(string type1, string type2) {
    if((type1 == "FLOAT" and type2 == "CHAR") or (type1 == "CHAR" and type2 == "FLOAT")) {
        return true;
    }
    return false;
}

void yyerror(const char* msg) {
    sem_errors.push_back("syntax error in line " + to_string(countn+1));
    for(auto item: sem_errors)
        cout << item << endl;
    fprintf(stderr, "%s\n", msg);
    exit(1);
}

string get_temp() {
    if(free_temp.empty()){
        return "@t" + to_string(variable_count++);
    }
    string t=free_temp.front();
    free_temp.pop(); 
    return t; 
}

void PrintStack(stack<int> s) {
    if (s.empty())
        return;
    int x = s.top();
    s.pop();
    cout << x << ' ';
    PrintStack(s);
    s.push(x);
}

void print_symbol_table() {
    ofstream fout("symboltable.txt");
    if (!fout.is_open()) {
        cerr << "Error: Unable to open symboltable.txt for writing\n";
        return;
    }

    fout << "======================= SYMBOL TABLE =======================\n\n";

    // Iterate through all functions in func_table
    for (const auto &func_pair : func_table) {
        const string &func_name = func_pair.first;
        const func_info &func = func_pair.second;

        fout << "Function: " << func_name << "\n";
        fout << "Return Type: " << func.return_type << "\n";
        fout << "Parameters: " << func.num_params << "\n";
        fout << string(60, '-') << "\n";
        fout << left << setw(15) << "Variable"
             << setw(10) << "Type"
             << setw(8)  << "Scope"
             << setw(8)  << "Array?"
             << setw(10) << "Size"
             << setw(10) << "Line"
             << "\n";
        fout << string(60, '-') << "\n";

        // Iterate through symbol table entries
        for (const auto &var_pair : func.symbol_table) {
            const string &var_name = var_pair.first;
            const var_info &info = var_pair.second;

            fout << left << setw(15) << var_name
                 << setw(10) << info.data_type
                 << setw(8)  << info.scope
                 << setw(8)  << (info.isArray ? "Yes" : "No")
                 << setw(10) << info.size
                 << setw(10) << info.line_number
                 << "\n";
        }

        fout << "\n";
    }

    fout.close();
    cout << "Symbol table written to symboltable.txt\n";
}