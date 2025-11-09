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
    #include <map>
    #include <stack>
    #include <algorithm>
    #include <fstream>
    #include <set>
    #include <iomanip>

    using namespace std;

    void yyerror(const char *s);
    int yylex();
    int yywrap();
    int yytext();

    bool multiple_declaration(string variable);
    bool is_reserved_word(string id);
    bool function_check(string variable, int flag);
    bool type_check(string type1, string type2);
    bool check_type(string l, string r);
    string get_temp();
    int get_type_size(const string &dtype);

    queue<string> free_temp;
    set<string> const_temps;
    void PrintStack(stack<int> s);
    void print_func_table();

    struct var_info {
        string data_type;
        int scope;
        int size;   // for arrays
        int isArray;
        int line_number;
        string visibility = "private";
    };

    bool lookup_var_info(const string& name, var_info*& out_info);
    bool check_decl_any(const string& variable);
    bool check_scope_any(const string& variable);
    bool get_id_type(const string& id, string& out_type);
    void print_class_table();

    set<string> valid_libs = {"\"io.kik\"", "\"string.kik\"", "\"math.kik\"", "\"io.kik\""};
    set<string> imported_libs;
    vector<string> tac;
    map<string, string> temp_map;

    int variable_count = 0;
    int label_counter = 0;

    vector<string> sem_errors;

    int temp_index;
    int temp_label;

    stack<int> loop_continue, loop_break;
    stack<pair<string, vector<string>>> func_call_id;
    stack<int> scope_history;
    int scope_counter = 0;

    // for array declaration with initialization
    string curr_array;
    int arr_index=0;

    extern int countn;

    struct func_info {
        string return_type;
        int num_params;
        vector<string> param_types;
        unordered_map<string, struct var_info> symbol_table;
        string visibility = "private";
    };

    int has_return_stmt;

    unordered_map<string, struct func_info> func_table;
    string curr_func_name;
    vector<string> curr_func_param_type;

    struct class_info {
        string parent;
        unordered_map<string, var_info> members;
        unordered_map<string, func_info> methods;
    };

    unordered_map<string, struct class_info> class_table;
    string curr_class_name;
    bool in_method = false;
    string current_visibility = "private";

    vector<string> reserved = {"import", "int", "float", "char", "bool", "string", "void", "if", "else", "for", "while", "break", "continue", "kik", "return", "switch", "case", "input", "output"};

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
        char case_body[5];
        char id[5];
        char temp[5];
        int nParams;
    } node;
}

%token <node> IMPORT INT CHAR FLOAT BOOL STRING VOID RETURN INT_NUM FLOAT_NUM ID LEFTSHIFT RIGHTSHIFT LE GE EQ NE GT LT AND OR NOT ADD SUBTRACT DIVIDE MULTIPLY MODULO BITAND BITOR NEGATION XOR STRING_LITERAL CHARACTER CC OC CS OS CF OF COMMA COLON SCOL SWITCH CASE BREAK DEFAULT IF ELIF ELSE WHILE FOR CONTINUE CLASS PUBLIC PRIVATE PROTECTED NEW DOT

%type <node> program import_stmt class_def inheritance_opt class_body access_specifier_block_list access_specifier_block access_specifier class_members class_member constructor_def destructor_def object_creation member_access class_list func func_prefix param_list param stmt_list stmt declaration return_stmt data_type expr primary_expr unary_expr unary_op const assign if_stmt elif_stmt else_stmt switch_stmt case_stmt case_stmt_list while_loop_stmt for_loop_stmt postfix_expr func_call arg_list arg

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

program         :       top_level_list
                        ;

top_level_list  :       top_level_list top_level_stmt
                        | 
                        ;

top_level_stmt  :       import_stmt
                        | func
                        | class_def
                        ;

class_def       :       CLASS ID {
                            curr_class_name = string($2.lexeme);
                            curr_func_name = "";
                            in_method = false; 
                            if (class_table.find(curr_class_name) != class_table.end()) {
                                sem_errors.push_back("Duplicate class definition: " + curr_class_name);
                            } else {
                                class_table[curr_class_name] = class_info();
                            }
                        } inheritance_opt OF class_body CF {
                            curr_class_name = "";
                            curr_func_name = "";
                            in_method = false;
                        }
                        ;

inheritance_opt :       COLON ID {
                            string parent_name = string($2.lexeme);
                            if (class_table.find(parent_name) == class_table.end()) {
                                sem_errors.push_back("Parent class '" + parent_name + "' not defined before inheritance.");
                            } else {
                                class_table[curr_class_name].parent = parent_name;
                            }
                        }
                        |
                        ;


class_body      :       access_specifier_block_list
                        |
                        ;

access_specifier_block_list :   access_specifier_block access_specifier_block_list
                                | access_specifier_block
                                ;

access_specifier_block      :   access_specifier COLON {
                                    current_visibility = string($1.lexeme);
                                } class_members
                                ;

access_specifier:       PUBLIC
                        | PRIVATE
                        | PROTECTED
                        ;

class_members   :       class_member class_members
                        | class_member
                        ;

class_member    :       declaration
                        | func {
                            if (!curr_class_name.empty()) {
                                class_table[curr_class_name].methods[curr_func_name] = func_table[curr_func_name];
                            }
                        }
                        | constructor_def {
                            // Register constructor under class
                            if (!curr_class_name.empty()) {
                                class_table[curr_class_name].methods[curr_func_name] = func_table[curr_func_name];
                            }
                        }
                        | destructor_def {
                            // Register destructor under class
                            if (!curr_class_name.empty()) {
                                class_table[curr_class_name].methods[curr_func_name] = func_table[curr_func_name];
                            }
                        }
                        | object_creation
                        ;

constructor_def :       ID OC {
                            in_method = true;
                            curr_func_name = string($1.lexeme);

                            if (curr_class_name.empty()) {
                                sem_errors.push_back("Constructor '" + curr_func_name +
                                                    "' defined outside class context.");
                            } else if (curr_class_name != curr_func_name) {
                                sem_errors.push_back("Constructor '" + curr_func_name +
                                                    "' must match class name '" + curr_class_name + "'");
                            }

                            // (Re)initialize func_table entry for this constructor
                            func_table[curr_func_name].return_type = "void";   // constructors return void
                            func_table[curr_func_name].num_params  = 0;
                            func_table[curr_func_name].param_types.clear();
                            func_table[curr_func_name].symbol_table.clear();
                            func_table[curr_func_name].visibility  = current_visibility;
                        } param_list CC OF {
                            func_table[curr_func_name].num_params = $4.nParams;
                            scope_history.push(++scope_counter);
                        } stmt_list CF {
                            scope_history.pop();
                            --scope_counter;

                            if (!curr_class_name.empty()) {
                                class_table[curr_class_name].methods[curr_func_name] = func_table[curr_func_name];
                            }
                            in_method = false;
                        }
                        ;


destructor_def  :       NEGATION ID OC CC OF {
                            in_method = true;
                            curr_func_name = "~" + string($2.lexeme);

                            if (curr_class_name.empty() || curr_class_name != string($2.lexeme)) {
                                sem_errors.push_back("Destructor name must match class name '" + curr_class_name + "'");
                            }

                            func_table[curr_func_name].return_type = "void";
                            func_table[curr_func_name].num_params = 0;
                            func_table[curr_func_name].param_types.clear();
                            func_table[curr_func_name].symbol_table.clear();
                            func_table[curr_func_name].visibility  = current_visibility;

                            scope_history.push(++scope_counter);
                        } stmt_list CF {
                            scope_history.pop();
                            --scope_counter;

                            if (!curr_class_name.empty())
                                class_table[curr_class_name].methods[curr_func_name] = func_table[curr_func_name];

                            in_method = false;
                        }
                        ;

object_creation :       ID ID ASSIGN NEW ID OC arg_list CC SCOL {
                            string classType = string($1.lexeme);
                            string objName = string($2.lexeme);
                            string newType = string($5.lexeme);

                            if (class_table.find(classType) == class_table.end()) {
                                sem_errors.push_back("Undefined class type '" + classType +
                                                    "' at line " + to_string(countn+1));
                            }
                            if (class_table.find(newType) == class_table.end()) {
                                sem_errors.push_back("Undefined class type '" + newType +
                                                    "' at line " + to_string(countn+1));
                            }

                            if (classType != newType) {
                                sem_errors.push_back("Type mismatch: cannot assign object of class '" + newType +
                                                    "' to variable of class '" + classType + "' at line " + to_string(countn+1));
                            }

                            if (!curr_class_name.empty() && !in_method) {
                                // inside a class as member
                                class_table[curr_class_name].members[objName] =
                                    { classType, scope_counter, 0, 0, countn+1 };
                            } else {
                                // inside function or globally
                                func_table[curr_func_name].symbol_table[objName] =
                                    { classType, scope_counter, 0, 0, countn+1 };
                            }

                            tac.push_back("- " + classType + " " + objName);
                            tac.push_back(objName + " = new " + newType);
                        }
                        | ID ID SCOL {
                            string classType = string($1.lexeme);
                            string objName = string($2.lexeme);

                            if (class_table.find(classType) == class_table.end()) {
                                sem_errors.push_back("Undefined class type '" + classType + "' for object '" + objName +
                                                    "' at line " + to_string(countn+1));
                            }

                            if (!curr_class_name.empty() && !in_method) {
                                // inside class
                                class_table[curr_class_name].members[objName] =
                                    { classType, scope_counter, 0, 0, countn+1 };
                            } else {
                                // inside function
                                func_table[curr_func_name].symbol_table[objName] =
                                    { classType, scope_counter, 0, 0, countn+1 };
                            }

                            tac.push_back("- " + classType + " " + objName);
                        }
                        ;

member_access   :       ID DOT ID
                        | ID DOT func_call
                        ;

import_stmt     :       IMPORT STRING_LITERAL SCOL {
                            string lib = string($2.lexeme);
                            if(valid_libs.find(lib) == valid_libs.end()){
                                sem_errors.push_back("Library " + lib + " not found at line " + to_string(countn+1));
                            }
                            else if(imported_libs.find(lib) != imported_libs.end()){
                                sem_errors.push_back("Library " + lib + " already imported at line " + to_string(countn+1));  
                            }
                            else {
                                imported_libs.insert(lib);
                                // Auto-register built-in library functions if needed
                                if (lib == "\"io.kik\"") {
                                    func_info input_func;
                                    input_func.return_type = "VOID";
                                    input_func.num_params = 1;
                                    input_func.param_types = {"INT"};
                                    func_table["input"] = input_func;

                                    func_info output_func;
                                    output_func.return_type = "VOID";
                                    output_func.num_params = 1;
                                    output_func.param_types = {"STRING"};
                                    func_table["output"] = output_func;
                                } else if (lib == "\"string.kik\"") {
                                    func_info strlen_func;
                                    strlen_func.return_type = "INT";
                                    strlen_func.num_params = 1;
                                    strlen_func.param_types = {"STRING"};
                                    func_table["strlen"] = strlen_func;
                                } else if (lib == "\"math.kik\"") {
                                    func_info max_func;
                                    max_func.return_type = "INT";
                                    max_func.num_params = 2;
                                    max_func.param_types = {"INT", "INT"};
                                    func_table["max"] = max_func;
                                }
                            }
                        }
                        ;

func            :       func_prefix OF {
                            has_return_stmt = 0;
                            if (!curr_class_name.empty()) in_method = true;
                            scope_history.push(++scope_counter);
                        } stmt_list CF {
                            if(func_table[curr_func_name].return_type != "void" && has_return_stmt == 0){
                                sem_errors.push_back("Return stmt not there for function: " + curr_func_name);
                            }
                            scope_history.pop();
                            --scope_counter;
                            tac.push_back("end:\n");
                            has_return_stmt = 0;
                            in_method = false;
                        }

func_prefix     :       data_type ID {
                            string funcName = string($2.lexeme);

                            // Allow same function name in different classes
                            if (curr_class_name.empty()) {
                                // Global function (must be unique)
                                if (func_table.find(funcName) != func_table.end()) {
                                    sem_errors.push_back("Error: Duplicate function name - " + funcName);
                                }
                            } else {
                                // Class method (check for override)
                                auto &cls = class_table[curr_class_name];
                                string parent = cls.parent;

                                bool isOverride = false;

                                // Check if parent defines this method
                                while (!parent.empty()) {
                                    if (class_table[parent].methods.find(funcName) != class_table[parent].methods.end()) {
                                        isOverride = true;
                                        break;
                                    }
                                    parent = class_table[parent].parent;
                                }

                                if (isOverride) {
                                    // Optionally note override (don’t raise error)
                                    tac.push_back("# " + funcName + " overrides parent method");
                                } else if (cls.methods.find(funcName) != cls.methods.end()) {
                                    sem_errors.push_back("Duplicate method '" + funcName +
                                                        "' in class '" + curr_class_name + "'");
                                }
                            }

                            // Record TAC label
                            tac.push_back(funcName + ": " + string($1.type));
                            curr_func_name = funcName;
                        } OC param_list CC {
                            func_table[curr_func_name].return_type = string($1.type);
                            func_table[curr_func_name].num_params  = $5.nParams;

                            // Store method properly inside class if inside one
                            if (!curr_class_name.empty()) {
                                func_table[curr_func_name].visibility = current_visibility;
                                class_table[curr_class_name].methods[curr_func_name] = func_table[curr_func_name];
                            }
                        }
                        | VOID ID {
                            string funcName = string($2.lexeme);

                            // Global uniqueness check
                            if (curr_class_name.empty()) {
                                if (func_table.find(funcName) != func_table.end()) {
                                    sem_errors.push_back("Error: Duplicate function name - " + funcName);
                                }
                            } else {
                                // Class method override check
                                auto &cls = class_table[curr_class_name];
                                string parent = cls.parent;
                                bool isOverride = false;

                                while (!parent.empty()) {
                                    if (class_table[parent].methods.find(funcName) != class_table[parent].methods.end()) {
                                        isOverride = true;
                                        break;
                                    }
                                    parent = class_table[parent].parent;
                                }

                                if (isOverride) {
                                    tac.push_back("# " + funcName + " overrides parent method");
                                } else if (cls.methods.find(funcName) != cls.methods.end()) {
                                    sem_errors.push_back("Duplicate method '" + funcName +
                                                        "' in class '" + curr_class_name + "'");
                                }
                            }

                            tac.push_back(funcName + ": void");
                            curr_func_name = funcName;
                            func_table[curr_func_name].visibility = current_visibility;
                        } OC param_list CC {
                            func_table[curr_func_name].return_type = "void";
                            func_table[curr_func_name].num_params  = $5.nParams;

                            if (!curr_class_name.empty()) {
                                class_table[curr_class_name].methods[curr_func_name] = func_table[curr_func_name];
                            }
                        }
                        ;
 
param_list      :       param {
                            int typeSize = get_type_size(string($1.type));
                            func_table[curr_func_name].param_types.push_back(string($1.type));
                            func_table[curr_func_name].symbol_table[string($1.lexeme)] = { string($1.type), scope_counter+1, typeSize, 0, countn+1 };
                            tac.push_back("- arg " + string($1.type) + " " + string($1.lexeme));                       
                        } COMMA param_list {
                            $$.nParams = $4.nParams + 1;
                        }
                        | param {
                            $$.nParams = 1;
                            int typeSize = get_type_size(string($1.type));
                            func_table[curr_func_name].param_types.push_back(string($1.type));
                            func_table[curr_func_name].symbol_table[string($1.lexeme)] = { string($1.type), scope_counter+1, typeSize, 0, countn+1 };
                            tac.push_back("- arg " + string($1.type) + " " + string($1.lexeme));
                        }
                        | {
                            $$.nParams = 0;
                        }
                        ;
 
param           :       data_type ID {
                            $$.nParams = 1;
                            strcpy($$.type, $1.type);
                            strcpy($$.lexeme, $2.lexeme); 
                        }
                        ;

stmt_list       :       stmt stmt_list
                        |
                        ;
                
stmt            :       declaration
                        |   assign SCOL
                        |   expr SCOL
                        |   return_stmt SCOL
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
                        |   switch_stmt
                        |   object_creation
                        ;

declaration     :       data_type ID SCOL {
                            string id = string($2.lexeme);
                            string dtype = string($1.type);
                            int typeSize = get_type_size(dtype);

                            if (!is_reserved_word(id) && !multiple_declaration(id)) {           // is this req??, comment it out???????
                                if (!curr_class_name.empty() && !in_method) {
                                    class_table[curr_class_name].members[id] = { dtype, scope_counter, typeSize, 0, countn+1, current_visibility };
                                } else {
                                    tac.push_back("- " + dtype + " " + id);
                                    func_table[curr_func_name].symbol_table[id] = { dtype, scope_counter, typeSize, 0, countn+1 };
                                }
                            }
                        }
                        |   data_type ID ASSIGN expr SCOL {
                                string id = string($2.lexeme);
                                string dtype = string($1.type);
                                string value = string($4.lexeme);
                                int typeSize = get_type_size(dtype);

                                if (!is_reserved_word(id) && !multiple_declaration(id)) {       // COMMENT???? mult_decl
                                    check_type(dtype, string($4.type));

                                    if (!curr_class_name.empty() && !in_method) {
                                        class_table[curr_class_name].members[id] = { dtype, scope_counter, typeSize, 0, countn+1, current_visibility };
                                    } else {
                                        if (dtype == "STRING" && value.front() == '"' && value.back() == '"') {
                                            string raw = value.substr(1, value.size() - 2);
                                            int len = raw.size();

                                            tac.push_back("- INT " + id + " [ " + to_string(len + 1) + " ]");
                                            for (int i = 0; i < len; ++i)
                                                tac.push_back(id + " [ " + to_string(i) + " ] = " + to_string((int)raw[i]) + " INT");
                                            tac.push_back(id + " [ " + to_string(len) + " ] = 0 INT");

                                            func_table[curr_func_name].symbol_table[id] = { "INT", scope_counter, len+1, 1, countn+1 };
                                        } else {
                                            tac.push_back("- " + dtype + " " + id);
                                            tac.push_back(id + " = " + value + " " + dtype);
                                            func_table[curr_func_name].symbol_table[id] = { dtype, scope_counter, typeSize, 0, countn+1 };
                                        }
                                    }
                                }
                            }
                        |   data_type ID OS INT_NUM CS SCOL {
                                string id = string($2.lexeme);
                                string dtype = string($1.type);
                                int arr_size = 0;
                                int typeSize = get_type_size(dtype);
                                try { arr_size = stoi(string($4.lexeme)); } catch(...) { arr_size = 0; }

                                if (!is_reserved_word(id) && !multiple_declaration(id)) {
                                    if (!curr_class_name.empty() && !in_method) {
                                        class_table[curr_class_name].members[id] = { dtype, scope_counter, arr_size, 1, countn+1, current_visibility };
                                    } else {
                                        tac.push_back("- " + dtype + " " + id + " [ " + to_string(arr_size) + " ] ");
                                        func_table[curr_func_name].symbol_table[id] = { dtype, scope_counter, arr_size, 1, countn+1 };
                                    }
                                }
                            }
                        | data_type ID OS INT_NUM CS ASSIGN {
                            string id = string($2.lexeme);
                            string dtype = string($1.type);
                            int arr_size = 0;
                            int typeSize = get_type_size(dtype);
                            try { arr_size = stoi(string($4.lexeme)); } catch(...) { arr_size = 0; }

                            if (!is_reserved_word(id) && !multiple_declaration(id)) {
                                if (!curr_class_name.empty() && !in_method) {
                                    class_table[curr_class_name].members[id] = { dtype, scope_counter, arr_size, 1, countn+1, current_visibility };
                                } else {
                                    tac.push_back("- " + dtype + " " + id + " [ " + to_string(arr_size) + " ] ");
                                    func_table[curr_func_name].symbol_table[id] = { dtype, scope_counter, arr_size, 1, countn+1 };

                                    // ✅ set globals for arr_values
                                    curr_array = id;
                                    arr_index = 0;
                                }
                            }
                        } OF arr_values CF SCOL
                        ;

arr_values      :       const {
                            string arr_name = curr_array;
                            check_type(func_table[curr_func_name].symbol_table[arr_name].data_type, string($1.type));

                            tac.push_back(arr_name + " [ " + to_string(arr_index++) + " ] = " +
                                            string($1.lexeme) + " " +
                                            func_table[curr_func_name].symbol_table[arr_name].data_type);

                            int declared_size = func_table[curr_func_name].symbol_table[arr_name].size;
                            if (declared_size != 0 && arr_index > declared_size) {
                                sem_errors.push_back("Line no: " +
                                    to_string(func_table[curr_func_name].symbol_table[arr_name].line_number) +
                                    " error: too many initializers for ‘array [" + to_string(declared_size) + "]’");
                            }
                        } COMMA arr_values
                        | const {
                            string arr_name = curr_array;
                            check_type(func_table[curr_func_name].symbol_table[arr_name].data_type, string($1.type));

                            tac.push_back(arr_name + " [ " + to_string(arr_index++) + " ] = " +
                                            string($1.lexeme) + " " +
                                            func_table[curr_func_name].symbol_table[arr_name].data_type);

                            int declared_size = func_table[curr_func_name].symbol_table[arr_name].size;
                            if (declared_size != 0 && arr_index > declared_size) {
                                sem_errors.push_back("Line no: " +
                                    to_string(func_table[curr_func_name].symbol_table[arr_name].line_number) +
                                    " error: too many initializers for ‘array [" + to_string(declared_size) + "]’");
                            }

                            // ✅ Final element of array
                            // If array size not declared (==0), infer it from arr_index
                            if (func_table[curr_func_name].symbol_table[arr_name].size == 0)
                                func_table[curr_func_name].symbol_table[arr_name].size = arr_index;

                            arr_index = 0; // ✅ reset only once, at end of array initialization
                        }
                        ;

return_stmt     :       RETURN expr {
                            check_type(func_table[curr_func_name].return_type, string($2.type));
                            tac.push_back("return " + string($2.lexeme) + " " + func_table[curr_func_name].return_type);
                            has_return_stmt = 1;

                            if(const_temps.find(string($2.lexeme)) == const_temps.end() && $2.lexeme[0] == '@') free_temp.push(string($2.lexeme));
                        }  
                        ;

data_type       :       INT { strcpy($$.type, "INT"); }
                        |   CHAR { strcpy($$.type, "CHAR"); }
                        |   FLOAT { strcpy($$.type, "FLOAT"); }
                        |   STRING { strcpy($$.type, "STRING"); }
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
                                tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($2.lexeme) + " " + string($3.lexeme) + " " + string($$.type));
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
                            }
                        |   expr DIVIDE expr {
                                add_tac($$, $1, $2, $3)
                                tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($2.lexeme) + " " + string($3.lexeme) + " " + string($$.type));
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
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
                                tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($2.lexeme) + " " + string($3.lexeme) + " " + string($$.type));
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
                            }
                        |   expr OR expr {
                                add_tac($$, $1, $2, $3)
                                tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($2.lexeme) + " " + string($3.lexeme) + " " + string($$.type));
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
                            }
                        |   expr MODULO expr {
                                add_tac($$, $1, $2, $3)
                                tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($2.lexeme) + " " + string($3.lexeme) + " " + string($$.type));
                                if(const_temps.find(string($1.lexeme)) == const_temps.end() && $1.lexeme[0] == '@') free_temp.push(string($1.lexeme));
                                if(const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@') free_temp.push(string($3.lexeme));
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
                        |   NEW ID OC arg_list CC {
                                // semantic type of `new Class()` is the class name
                                strcpy($$.type, $2.lexeme);
                                string t = get_temp();
                                sprintf($$.lexeme, t.c_str());
                                tac.push_back(string($$.lexeme) + " = new " + string($2.lexeme));
                            }
                        ;

postfix_expr    :       func_call {
                            strcpy($$.type, $1.type);
                            sprintf($$.lexeme, "%s", $1.lexeme);
                        }
                        | ID OS expr CS {
                            // Verify declaration in either local or class member
                            if (check_decl_any(string($1.lexeme))) {
                                // Ensure it actually is an array
                                var_info* info = nullptr;
                                lookup_var_info(string($1.lexeme), info);
                                if (info && info->isArray == 0) {
                                    sem_errors.push_back("Variable is not an array");
                                }
                                check_scope_any(string($1.lexeme));

                                // Type comes from the array's element type (same as data_type field)
                                strcpy($$.type, info ? info->data_type.c_str() : "UNKNOWN");
                            } else {
                                strcpy($$.type, "UNKNOWN");
                            }

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
                            var_info* info = nullptr;

                            if (lookup_var_info(string($1.lexeme), info)) {
                                check_scope_any(string($1.lexeme));

                                strcpy($$.type, info->data_type.c_str());
                                strcpy($$.lexeme, $1.lexeme);
                            } 
                            else {
                                sem_errors.push_back("Variable not declared in line " + to_string(countn+1) + " before usage.");
                                strcpy($$.type, "UNKNOWN");
                                strcpy($$.lexeme, "error");
                            }
                        }
                        |   const {
                                strcpy($$.type, $1.type);

                                if (strcmp($1.type, "STR") == 0) {
                                    strcpy($$.lexeme, $1.lexeme);
                                } else {
                                    string t = get_temp();
                                    sprintf($$.lexeme, t.c_str());
                                    tac.push_back(string($$.lexeme) + " = " + string($1.lexeme) + " " + string($$.type));
                                    temp_map[string($1.lexeme)] = string($$.lexeme);
                                    const_temps.insert(t);
                                }
                            }
                        |   OC expr CC {
                                strcpy($$.type, $2.type);
                                strcpy($$.lexeme, $2.lexeme);
                            }
                        |   member_access {
                                strcpy($$.type, $1.type);
                                strcpy($$.lexeme, $1.lexeme);
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
                        | STRING_LITERAL {
                            strcpy($$.type, "STR");
                            strcpy($$.lexeme, $1.lexeme);
                        }
                        ;

assign          :       ID ASSIGN expr {
                            var_info* info = nullptr;
                            if (lookup_var_info(string($1.lexeme), info)) {
                                check_scope_any(string($1.lexeme));

                                check_type(info->data_type, string($3.type));
                                tac.push_back(string($1.lexeme) + " = " + string($3.lexeme) + " " + info->data_type);

                                if (const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@')
                                    free_temp.push(string($3.lexeme));
                            } else {
                                sem_errors.push_back("Variable '" + string($1.lexeme) + "' not declared before assignment at line " + to_string(countn+1));
                            }
                        }
                        |   ID OS expr CS ASSIGN expr {
                                var_info* info = nullptr;
                                if (lookup_var_info(string($1.lexeme), info)) {
                                    check_scope_any(string($1.lexeme));

                                    if (info->isArray == 0) {
                                        sem_errors.push_back("Line no " + to_string(countn+1) + " : Variable '" + string($1.lexeme) + "' is not an array");
                                    }

                                    check_type(info->data_type, string($6.type));
                                    tac.push_back(string($1.lexeme) + " [ " + string($3.lexeme) + " ] = " + string($6.lexeme) + " " + info->data_type);

                                    if (const_temps.find(string($6.lexeme)) == const_temps.end() && $6.lexeme[0] == '@')
                                        free_temp.push(string($6.lexeme));
                                } else {
                                    sem_errors.push_back("Array variable '" + string($1.lexeme) + "' not declared before usage at line " + to_string(countn+1));
                                }
                            }
                        |   member_access ASSIGN expr {
                                check_type(string($1.type), string($3.type));

                                tac.push_back(string($1.lexeme) + " = " + string($3.lexeme) + " " + string($1.type));

                                if (const_temps.find(string($3.lexeme)) == const_temps.end() && $3.lexeme[0] == '@')
                                    free_temp.push(string($3.lexeme));
                            }

if_stmt         :       IF {
                            sprintf($1.parentNext, "#L%d", label_counter++);
                        } expr COLON { 
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
                        } expr COLON {
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

else_stmt       :       ELSE COLON OF {
                            scope_history.push(++scope_counter);
                        } stmt_list CF {
                            scope_history.pop(); --scope_counter;
                        }
                        |
                        ;


switch_stmt     :       SWITCH {
                            int temp_label = label_counter;
                            loop_break.push(temp_label);
                            sprintf($1.parentNext, "#L%d", label_counter++);
                        } OC ID {
                            temp_index = variable_count;
                            tac.push_back("@t" + to_string(variable_count++) + " = " + string($4.lexeme) + " " + func_table[curr_func_name].symbol_table[string($4.lexeme)].data_type);
                        } CC OF case_stmt_list {
                            // strcpy($8.id, $4.lexeme);
                            // strcpy($8.parentNext, $1.parentNext);
                        } default_stmt CF {
                            tac.push_back(string($1.parentNext) + ":");
                            loop_break.pop();
                        }
                        ;

case_stmt_list  :       case_stmt case_stmt_list {
                            strcpy($1.id, $$.id);
                            strcpy($1.parentNext, $$.parentNext);
                        }
                        |
                        ;

case_stmt       :       CASE {
                            // tac.push_back(string($4.if_body) + ":");
                        } OC const {
                            char* hold = const_cast<char*>(to_string(variable_count).c_str());
                            sprintf($4.temp, "%s", hold);
                            tac.push_back("@t" + to_string(variable_count++) + " = " + string($4.lexeme) + " " + string($4.type));
                            tac.push_back("@t" + to_string(variable_count++) + " = " + "@t" + to_string(temp_index) + " == " + "@t" + string($4.temp) + " INT");
                            tac.push_back("if @t" + to_string(variable_count-1) + " GOTO #L" + to_string(label_counter) + " else GOTO #L" + to_string(label_counter+1));
                            tac.push_back("#L" + to_string(label_counter) + ":");
                            sprintf($4.case_body, "#L%d", label_counter++);
                            sprintf($4.parentNext, "#L%d", label_counter++);
                        } CC COLON stmt_list {
                            tac.push_back(string($4.parentNext) + ":");
                        } 

default_stmt    :       DEFAULT COLON stmt_list
                        |
                        ;                       

while_loop_stmt :       WHILE {
                            sprintf($1.loop_body, "#L%d", label_counter); 
                            loop_continue.push(label_counter++);
                            tac.push_back("\n" + string($1.loop_body) + ":");
                        } expr COLON {
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

for_loop_stmt   :       FOR declaration {
                            sprintf($1.loop_body, "#L%d", label_counter++); 
                            tac.push_back("\n" + string($1.loop_body) + ":");
                        } expr SCOL COLON {  
                            sprintf($6.if_body, "#L%d", label_counter++); 

                            loop_break.push(label_counter);
                            sprintf($6.else_body, "#L%d", label_counter++); 

                            tac.push_back("\nif " + string($6.lexeme) + " GOTO " + string($6.if_body) + " else GOTO " + string($6.else_body));

                            sprintf($6.loop_body, "#L%d", label_counter); 
                            loop_continue.push(label_counter++);
                            tac.push_back("\n" + string($6.loop_body) + ":");

                            if(const_temps.find(string($6.lexeme)) == const_temps.end() && $6.lexeme[0] == '@') free_temp.push(string($6.lexeme));
                        } assign COLON {
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


func_call       :       ID {
                            string func_name = string($1.lexeme);

                            if (func_table.find(func_name) == func_table.end()) {
                                sem_errors.push_back("Function '" + func_name + "' not declared before use at line " + to_string(countn + 1));
                            } else {
                                if ((func_name == "input" || func_name == "output") &&
                                    imported_libs.find("\"io.kik\"") == imported_libs.end()) {
                                    sem_errors.push_back("Function '" + func_name +
                                        "' used without importing \"io.kik\" at line " + to_string(countn + 1));
                                }
                                if (func_name == "strlen" &&
                                    imported_libs.find("\"string.kik\"") == imported_libs.end()) {
                                    sem_errors.push_back("Function 'strlen' used without importing \"string.kik\" at line " + to_string(countn + 1));
                                }
                                if (func_name == "max" &&
                                    imported_libs.find("\"math.kik\"") == imported_libs.end()) {
                                    sem_errors.push_back("Function 'max' used without importing \"math.kik\" at line " + to_string(countn + 1));
                                }
                                func_call_id.push({func_name, func_table[func_name].param_types});
                            }
                        } OC arg_list CC  {
                            string func_name = string($1.lexeme);

                            if (func_table.find(func_name) != func_table.end()) {
                                strcpy($$.type, func_table[func_name].return_type.c_str());
                                sprintf($$.lexeme, get_temp().c_str());

                                tac.push_back(string($$.lexeme) + " = @call " + func_name + " " +
                                            func_table[func_name].return_type + " " +
                                            to_string(func_table[func_name].num_params));

                                func_call_id.pop();
                            } else {
                                strcpy($$.type, "UNKNOWN");
                                sprintf($$.lexeme, "error");
                            }
                        }
                        ;

arg_list        :       arg COMMA arg_list {
                            if (!func_call_id.empty()) {
                                auto &param_types = func_call_id.top().second;

                                if (!param_types.empty()) {
                                    string expected_type = param_types.back();
                                    param_types.pop_back();

                                    // Compare argument type
                                    if (!check_type(expected_type, string($1.type))) {
                                        sem_errors.push_back("Datatype mismatch for argument in function call at line " + to_string(countn + 1));
                                    }
                                } else {
                                    sem_errors.push_back("Too many arguments in function call at line " + to_string(countn + 1));
                                }
                            }
                        }
                        | arg {
                            if (!func_call_id.empty()) {
                                auto &param_types = func_call_id.top().second;

                                if (!param_types.empty()) {
                                    string expected_type = param_types.back();
                                    param_types.pop_back();

                                    if (!check_type(expected_type, string($1.type))) {
                                        sem_errors.push_back("Datatype mismatch for argument in function call at line " + to_string(countn + 1));
                                    }
                                } else {
                                    sem_errors.push_back("Too many arguments in function call at line " + to_string(countn + 1));
                                }
                            }
                        }
                        | {
                            if (!func_call_id.empty()) {
                                if (!func_call_id.top().second.empty()) {
                                    sem_errors.push_back("Too few arguments in function call at line " + to_string(countn + 1));
                                }
                            }
                        }
                        ;

arg             :       expr {
                            tac.push_back("param " + string($1.lexeme) + " " + string($1.type));
                        }
                        ;

%%

int main(int argc, char *argv[]) {
    yyparse();

    // Print all semantic errors, if any
    for (auto &item : sem_errors) {
        cout << item << endl;
    }

    if(sem_errors.size() > 0) {
        cout << "Total Semantic Errors: " << sem_errors.size() << endl;
        exit(0);
    }
        
    for(auto x: tac) 
        cout << x << endl;

    print_func_table();
    print_class_table();

    return 0;
}

bool multiple_declaration(string variable) {
    if (!curr_class_name.empty() && !in_method) {
        if (class_table[curr_class_name].members.find(variable) != class_table[curr_class_name].members.end()) {
            sem_errors.push_back("redeclaration of member '" + variable + "' in class '" + curr_class_name + "' at line " + to_string(countn+1));
            return true;
        }
        return false;
    }

    if (func_table[curr_func_name].symbol_table.find(variable) != func_table[curr_func_name].symbol_table.end()) {
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

bool lookup_var_info(const string& name, var_info*& out_info) {
    auto &locals = func_table[curr_func_name].symbol_table;
    auto it = locals.find(name);
    if (it != locals.end()) { out_info = &it->second; return true; }

    if (!curr_class_name.empty() && in_method) {
        string cls = curr_class_name;

        while (!cls.empty()) {
            auto &members = class_table[cls].members;
            auto cit = members.find(name);
            if (cit != members.end()) {
                out_info = &cit->second;
                return true;
            }

            // move up parent
            cls = class_table[cls].parent;
        }
    }
    return false;
}

bool check_decl_any(const string& variable) {
    var_info* info = nullptr;
    if (lookup_var_info(variable, info)) return true;
    sem_errors.push_back("Variable not declared in line " + std::to_string(countn+1) + " before usage.");
    return false;
}

bool check_scope_any(const string& variable) {
    var_info* info = nullptr;
    if (!lookup_var_info(variable, info)) {
        sem_errors.push_back("Variable '" + variable + "' not declared before usage at line " + to_string(countn + 1));
        return false;
    }

    if (!curr_class_name.empty() && in_method) {
        string cls = curr_class_name;
        while (!cls.empty()) {
            auto &members = class_table[cls].members;
            if (members.find(variable) != members.end()) {
                // Found the variable in this class or one of its parents — scope OK
                return true;
            }
            cls = class_table[cls].parent;  // climb up inheritance
        }
    }

    int var_scope = info->scope;
    std::stack<int> temp_stack(scope_history);

    while (!temp_stack.empty()) {
        if (temp_stack.top() == var_scope)
            return true;
        temp_stack.pop();
    }

    sem_errors.push_back("Scope of variable '" + variable + "' not matching in line " +
                         to_string(countn + 1) + ".");
    return false;
}

bool get_id_type(const std::string& id, std::string& out_type) {
    var_info* info = nullptr;
    if (!lookup_var_info(id, info)) return false;
    out_type = info->data_type;
    return true;
}

int get_type_size(const string &dtype) {
    if (dtype == "INT") return 4;
    if (dtype == "FLOAT") return 4;
    if (dtype == "CHAR") return 1;
    if (dtype == "BOOL") return 1;
    if (dtype == "STRING") return 20; // or whatever you prefer
    return 0;
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

void print_func_table() {
    ofstream fout("FunctionTable.txt");
    if (!fout.is_open()) {
        cerr << "Error: Unable to open FunctionTable.txt for writing\n";
        return;
    }

    fout << "======================= FUNCTION TABLE =======================\n\n";

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
}

void print_class_table() {
    ofstream fout("ClassTable.txt");
    if (!fout.is_open()) {
        cerr << "Error: Unable to open ClassTable.txt for writing\n";
        return;
    }

    fout << "================================= CLASS TABLE =================================\n\n";

    for (const auto &class_pair : class_table) {
        const string &class_name = class_pair.first;
        const class_info &cls = class_pair.second;

        fout << "Class: " << class_name;
        if (!cls.parent.empty())
            fout << "    (Parent: " << cls.parent << ")";
        fout << "\n\n";

        // 🔹 Print Members
        fout << "Members:\n";
        fout << string(90, '-') << "\n";
        fout << left << setw(25) << "Member"
             << setw(12) << "Type"
             << setw(12) << "Visibility"
             << setw(8)  << "Scope"
             << setw(8)  << "Array?"
             << setw(8)  << "Size"
             << setw(10) << "Line"
             << "\n";
        fout << string(90, '-') << "\n";

        if (cls.members.empty()) {
            fout << "(no members)\n";
        } else {
            for (const auto &mem_pair : cls.members) {
                const string &mname = mem_pair.first;
                const var_info &info = mem_pair.second;

                fout << left << setw(25) << mname
                     << setw(12) << info.data_type
                     << setw(12) << info.visibility
                     << setw(8)  << info.scope
                     << setw(8)  << (info.isArray ? "Yes" : "No")
                     << setw(8)  << info.size
                     << setw(10) << info.line_number
                     << "\n";
            }
        }
        fout << "\n";

        // 🔹 Print inherited members from parents
        string parent = cls.parent;
        bool inheritedPrinted = false;
        while (!parent.empty()) {
            const class_info &pinfo = class_table[parent];
            if (!pinfo.members.empty()) {
                if (!inheritedPrinted) {
                    fout << "Inherited Members:\n";
                    fout << string(90, '-') << "\n";
                    fout << left << setw(25) << "Member"
                         << setw(12) << "Type"
                         << setw(12) << "Visibility"
                         << setw(8)  << "Scope"
                         << setw(8)  << "Array?"
                         << setw(8)  << "Size"
                         << setw(10) << "Line"
                         << "\n";
                    fout << string(90, '-') << "\n";
                    inheritedPrinted = true;
                }
                for (const auto &mem_pair : pinfo.members) {
                    fout << left << setw(25)
                         << (mem_pair.first + " (from " + parent + ")")
                         << setw(12) << mem_pair.second.data_type
                         << setw(12) << mem_pair.second.visibility
                         << setw(8)  << mem_pair.second.scope
                         << setw(8)  << (mem_pair.second.isArray ? "Yes" : "No")
                         << setw(8)  << mem_pair.second.size
                         << setw(10) << mem_pair.second.line_number
                         << "\n";
                }
            }
            parent = pinfo.parent;
        }
        fout << "\n";

        // 🔹 Print Methods summary
        fout << "Methods (summary):\n";
        fout << string(90, '-') << "\n";
        fout << left << setw(30) << "Method"
             << setw(15) << "Return Type"
             << setw(12) << "Visibility"
             << setw(8)  << "#Params"
             << "Param Types"
             << "\n";
        fout << string(90, '-') << "\n";

        if (cls.methods.empty()) {
            fout << "(no methods)\n\n";
        } else {
            for (const auto &m_pair : cls.methods) {
                const string &mname = m_pair.first;
                const func_info &finfo = m_pair.second;

                // Check if this method overrides a parent method
                bool overrides = false;
                string overriddenFrom = "";
                string parentName = cls.parent;
                while (!parentName.empty()) {
                    if (class_table[parentName].methods.find(mname) !=
                        class_table[parentName].methods.end()) {
                        overrides = true;
                        overriddenFrom = parentName;
                        break;
                    }
                    parentName = class_table[parentName].parent;
                }

                // Join parameter types
                string param_types = "";
                for (size_t i = 0; i < finfo.param_types.size(); ++i) {
                    param_types += finfo.param_types[i];
                    if (i + 1 < finfo.param_types.size()) param_types += ", ";
                }

                string displayName = mname;
                if (overrides)
                    displayName += " (overrides " + overriddenFrom + ")";

                fout << left << setw(30) << displayName
                     << setw(15) << finfo.return_type
                     << setw(12) << finfo.visibility
                     << setw(8)  << finfo.num_params
                     << param_types
                     << "\n";
            }
            fout << "\n";

            // 🔹 Print each method's local symbol table (if any)
            for (const auto &m_pair : cls.methods) {
                const string &mname = m_pair.first;
                const func_info &finfo = m_pair.second;

                fout << "Method: " << mname << "  (Return: " << finfo.return_type
                     << ", Params: " << finfo.num_params
                     << ", Visibility: " << finfo.visibility << ")\n";
                fout << string(90, '-') << "\n";
                fout << left << setw(15) << "Variable"
                     << setw(10) << "Type"
                     << setw(8)  << "Scope"
                     << setw(8)  << "Array?"
                     << setw(10) << "Size"
                     << setw(10) << "Line"
                     << "\n";
                fout << string(90, '-') << "\n";

                if (finfo.symbol_table.empty()) {
                    fout << "(no local symbols)\n";
                } else {
                    for (const auto &v_pair : finfo.symbol_table) {
                        const string &vname = v_pair.first;
                        const var_info &vinfo = v_pair.second;

                        fout << left << setw(15) << vname
                             << setw(10) << vinfo.data_type
                             << setw(8)  << vinfo.scope
                             << setw(8)  << (vinfo.isArray ? "Yes" : "No")
                             << setw(10) << vinfo.size
                             << setw(10) << vinfo.line_number
                             << "\n";
                    }
                }
                fout << "\n";
            }
        }

        // 🔹 Print inherited methods
        string parent2 = cls.parent;
        bool inheritedMethodsPrinted = false;
        while (!parent2.empty()) {
            const class_info &pinfo = class_table[parent2];
            if (!pinfo.methods.empty()) {
                if (!inheritedMethodsPrinted) {
                    fout << "Inherited Methods:\n";
                    fout << string(90, '-') << "\n";
                    fout << left << setw(30) << "Method"
                         << setw(15) << "Return Type"
                         << setw(12) << "Visibility"
                         << setw(8)  << "#Params"
                         << "Param Types"
                         << "\n";
                    fout << string(90, '-') << "\n";
                    inheritedMethodsPrinted = true;
                }
                for (const auto &pm : pinfo.methods) {
                    // Join param types (optional)
                    string param_types = "";
                    for (size_t i = 0; i < pm.second.param_types.size(); ++i) {
                        param_types += pm.second.param_types[i];
                        if (i + 1 < pm.second.param_types.size()) param_types += ", ";
                    }

                    fout << left << setw(30)
                         << (pm.first + " (from " + parent2 + ")")
                         << setw(15) << pm.second.return_type
                         << setw(12) << pm.second.visibility
                         << setw(8)  << pm.second.num_params
                         << param_types
                         << "\n";
                }
            }
            parent2 = pinfo.parent;
        }

        fout << string(90, '=') << "\n\n";
    }

    fout.close();
}