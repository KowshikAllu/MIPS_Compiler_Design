#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <map>
#include <set>
#include <utility>
#include <cctype>
#include <cstdlib>
using namespace std;

vector<vector<string>> tac;
vector<string> headervec;
set<string> headerSet;
vector<string> stkasm;
map<string, pair<string, string>> constant;
map<string, pair<string, string>> local;
int local_idx = 0;
map<string, pair<string, string>> argument;
int arg_idx = 0;
map<string, pair<string, string>> temp;
int temp_idx = 0;
map<string, string> op_map;
map<string, int> strings;
int str_idx=0;

map<string, pair<int, int>> fun_var_count;
string curr_fun_name, curr_ret_type;


void initialize(){
    // adding binary operations
    op_map["+"] = "iadd";
    op_map["-"] = "isub";
    op_map["*"] = "imul";
    op_map["/"] = "idiv";
    op_map["%"] = "imod";
    op_map["=="] = "eq";
    op_map[">"] = "gt";
    op_map["<"] = "lt";
    op_map["&"] = "and";
    op_map["|"] = "or";
    op_map["<="] = "le";
    op_map[">="] = "ge";
    op_map["!="] = "neq";
}

vector<string> tokenize(string in){
    vector<string> res;
    string temp_t = "";
    for(int i=0; i<in.size(); i++){
        if(in[i] == ' '){
            res.push_back(temp_t);
            temp_t = "";
            while(i<in.size() && in[i] == ' '){
                i++;
            }
            i--;
        }
        else{
            if(in[i] == '"'){
                string str="";
                while(i<in.size() && in[i] != '\n')
                    str += in[i++];

                int l=0;
                while(in[i] != '"'){
                    i--;
                    l++;
                }

                temp_t = str.substr(0,str.length()-l+1);
            }
            else{
                temp_t += in[i];
            }
        }
    }
    if(temp_t.size())
        res.push_back(temp_t);
    return res;
}

void print(){
    for(auto i: tac){
        for(auto j: i){
            cout << j << " ";
        }
        cout << endl;
    }
}

bool isNumber(string& str){
    for (char const &c : str){      
        if (isdigit(c) == 0 && c != '.')
          return false;
    }
    return true;
}

bool isOperator(string op){
    if(op_map.find(op) != op_map.end())
        return true;
    return false;
}

pair<pair<string, string>, string> get_type(string var, string type){
    pair<pair<string, string>, string> temp_var;
    // CASE 1: Temporary variable (like @t0, @t1, etc.)
    if(var[0] == '@'){
        if(temp.find(var) == temp.end()){
            temp[var].first = to_string(temp_idx);
            temp[var].second = type;
            temp_idx++;
        }
        temp_var.first.first = temp[var].first;
        temp_var.first.second = temp[var].second;
        temp_var.second = "temp";
    }
    // CASE 2: Constant (number or character literal)
    // Example: 5, 10, 'a'
    else if(isNumber(var) || var[0] == '\''){
        if(constant.find(var) == constant.end()){
            constant[var].first = var;
            constant[var].second = type;
            // check for the constant type
        }
        temp_var.first.first = constant[var].first;
        temp_var.first.second = constant[var].second;
        temp_var.second = "constant";
    }
    // CASE 3 & 4: Function arguments or local variables
    else{
        if(argument.find(var) != argument.end()){
            temp_var.first.first = argument[var].first;
            temp_var.first.second = argument[var].second;
            temp_var.second = "argument";
        }
        // CASE 4: Local variable (inside function)
        else{
            if(local.find(var) == local.end()){
                local[var].first = to_string(local_idx);
                local[var].second = type;
                local_idx++;
            }
            temp_var.first.first = local[var].first;
            temp_var.first.second = local[var].second;
            temp_var.second = "local";
        }
    }
    return temp_var;
}

void conversion(){
    for(int i=0; i<tac.size(); i++){
        // Skip empty lines
        if (tac[i].empty()) {
            continue;
        }
        // Skip comment lines
        if (!tac[i][0].empty() && tac[i][0][0] == '/') {
            continue;
        }

        //-----------------------------------------
        // HANDLE LABELS AND FUNCTION ENDINGS
        //-----------------------------------------
        if(tac[i].size() == 1 && tac[i][0][tac[i][0].size()-1] == ':'){
            string ins = "";
            // --- LABELS like #L1: ---
            // not func names
            if(tac[i][0][0] == '#'){
                ins += "label ";
                ins += tac[i][0];
                stkasm.push_back(ins);
            }
            // --- FUNCTION END MARKER 'end:' ---
            else if(tac[i][0] == "end:"){
                fun_var_count[curr_fun_name] = {local_idx, temp_idx};
                if(curr_ret_type == "void"){
                    // stkasm.push_back("iconst constant 0 INT");
                    stkasm.push_back("ret");
                }
                local_idx = 0;
                temp_idx = 0;
                local.clear();
                argument.clear();
                temp.clear();
            }
        }
        //-----------------------------------------
        // HANDLE NON-LABEL TAC INSTRUCTIONS
        //-----------------------------------------
        if(tac[i].size() > 1){
            // CASE 1: BINARY OPERATIONS
            // e.g.   t0 = a + b INT
            if(tac[i].size() == 6 && tac[i][1] == "=" && isOperator(tac[i][3])){
                pair<pair<string, string>, string> type_a = get_type(tac[i][0], tac[i][5]);
                pair<pair<string, string>, string> type_b = get_type(tac[i][2], tac[i][5]);
                pair<pair<string, string>, string> type_c = get_type(tac[i][4], tac[i][5]);
                stkasm.push_back("iconst " + type_b.second + " " + type_b.first.first);
                stkasm.push_back("iconst " + type_c.second + " " + type_c.first.first);
                stkasm.push_back(op_map[tac[i][3]] + " " + tac[i][5]);
                // if(op_map[tac[i][3]] != "eq")
                // stkasm.push_back("pop " + type_a.second + " " + type_a.first.first + " " + type_a.first.second);
            }
            // CASE 2: TWO-TOKEN LINES
            else if(tac[i].size() == 2){
                // GOTO label
                if(tac[i][0] == "GOTO"){
                    stkasm.push_back("jmp " + tac[i][1]);
                }
                // FUNCTION HEADER (e.g. main: INT)
                else if(tac[i][0][tac[i][0].size()-1] == ':'){
                    string ins = tac[i][0];
                    // ins.pop_back();
                    // ins += " " + tac[i][1];
                    stkasm.push_back(ins);
                    curr_fun_name = tac[i][0].substr(0, tac[i][0].size()-1);
                    curr_ret_type = tac[i][1];
                }
            }
            // CASE 3: RETURN, LOCAL VAR DECL, I/O, PARAM
            else if(tac[i].size() == 3){
                // RETURN x INT
                if(tac[i][0] == "return"){
                    pair<pair<string, string>, string> type_a = get_type(tac[i][1], tac[i][2]);
                    // stkasm.push_back("iconst " + type_a.second + " " + type_a.first.first + " " + type_a.first.second);
                    // stkasm.push_back("pop argument 0 " + type_a.first.second);
                    stkasm.push_back("ret");
                }
                // VARIABLE DECLARATION (e.g. - INT x)
                else if(tac[i][0] == "-"){
                    // for local variable declaration
                    if(tac[i][1] == "STR")
                        continue;
                    if(tac[i].size() == 3){
                        local[tac[i][2]].first = to_string(local_idx++);
                        local[tac[i][2]].second = tac[i][1];
                    }
                }
                // PARAMETER passing (e.g. param a INT)
                else if(tac[i][0] == "param"){
                    pair<pair<string, string>, string> type_a = get_type(tac[i][1], tac[i][2]);
                    // stkasm.push_back("iconst " + type_a.second + " " + type_a.first.first + " " + type_a.first.second);
                }
                // INPUT (e.g. input a INT)
                else if(tac[i][0] == "input"){
                    pair<pair<string, string>, string> type_a = get_type(tac[i][1], tac[i][2]);
                    stkasm.push_back("scan " + type_a.second + " " + type_a.first.first + " " + tac[i][2]);
                }
                // OUTPUT (e.g. output a INT or output "msg" STR)
                else if(tac[i][0] == "output"){
                    // string literal
                    if(tac[i][2] == "STR"){
                        if(tac[i][1][0] == '"'){
                            stkasm.push_back("iconst data " + to_string(str_idx) + " " + tac[i][1] + " STR");
                            strings[tac[i][1]] = str_idx++;
                        }
                        stkasm.push_back("iconst data " + to_string(strings[tac[i][1]]) + " STR");
                    }
                    // variable or number
                    else{
                        pair<pair<string, string>, string> type_a = get_type(tac[i][1], tac[i][2]);
                        stkasm.push_back("iconst " + type_a.second + " " + type_a.first.first + " " + type_a.first.second);
                    }
                    stkasm.push_back("print " + tac[i][2]);
                }
            }
            // CASE 4: SIMPLE ASSIGNMENTS
            // e.g. a = 5 INT  or  t1 = t2 INT
            else if(tac[i].size() == 4){
                if(tac[i][1] == "arg"){
                    // function parameters
                    argument[tac[i][3]].first = to_string(arg_idx++);
                    argument[tac[i][3]].second = tac[i][2];
                }
                else{
                    if(tac[i][3] == "STR"){
                        stkasm.push_back("istr " + to_string(str_idx) + " " + tac[i][2]);
                        strings[tac[i][0]] = str_idx++;
                    }
                    // a = 5 INT  OR  t0 = t1 INT
                    else{
                        pair<pair<string, string>, string> type_a = get_type(tac[i][0], tac[i][3]);
                        pair<pair<string, string>, string> type_b = get_type(tac[i][2], tac[i][3]);
                        if(type_b.second == "constant")
                            stkasm.push_back("iconst " + tac[i][2]);
                        // else
                        //     stkasm.push_back("iconst " + type_b.second + " " + type_b.first.first + " " + type_b.first.second);
                        // stkasm.push_back("pop " + type_a.second + " " + type_a.first.first + " " + type_a.first.second);
                    }
                }
            }
            // CASE 5: UNARY OPERATORS
            // e.g. t0 = - t1 INT
            else if(tac[i].size() == 5){
                // unary operations : t0 = - t1 INT
                auto a = get_type(tac[i][0], tac[i][4]);
                auto b = get_type(tac[i][3], tac[i][4]);

                stkasm.push_back("iconst " + b.second + " " + b.first.first);
                if(tac[i][2] == "-")
                    stkasm.push_back("neg " + tac[i][4]);
                else
                    stkasm.push_back("not " + tac[i][4]);
                // stkasm.push_back("pop " + a.second + " " + a.first.first + " " + a.first.second);
            }
            // CASE 6: FUNCTION CALLS or ARRAY DECL
            // e.g. t0 = @call func INT  OR  arr INT [ 5 ]
            else if(tac[i].size() == 6){
                if(tac[i][2] == "@call"){
                    stkasm.push_back("invoke " + tac[i][3] + " " + tac[i][5]);
                    pair<pair<string, string>, string> a = get_type(tac[i][0], tac[i][4]);
                    // stkasm.push_back("iconst argument 0 " + tac[i][4]);
                    // stkasm.push_back("pop " + a.second + " " + a.first.first + " " + a.first.second);
                }
                else if(tac[i][3] == "["){
                    // array declarations
                    local[tac[i][2]].first = to_string(local_idx);
                    local_idx += stoi(tac[i][4]);
                    local[tac[i][2]].second = tac[i][1];
                }
            }
            // CASE 7: ARRAY ACCESS or CONDITIONAL JUMPS
            else if(tac[i].size() == 7){
                if(tac[i][1] == "["){
                    // ARRAY WRITE  arr[8] = t0 INT
                    auto a = get_type(tac[i][5], tac[i][6]);
                    auto b = get_type(tac[i][2], "INT");
                    stkasm.push_back("iconst " + a.second + " " + a.first.first);

                    stkasm.push_back("iconst constant " + local[tac[i][0]].first);
                    stkasm.push_back("iconst constant " + local[tac[i][0]].first);
                    stkasm.push_back("iconst constant " + local[tac[i][0]].first);
                    stkasm.push_back("iconst constant " + local[tac[i][0]].first);
                    stkasm.push_back("iadd");
                    stkasm.push_back("iadd");    
                    stkasm.push_back("iadd");
                    stkasm.push_back("iconst " + b.second + " " + b.first.first);
                    stkasm.push_back("iconst " + b.second + " " + b.first.first);
                    stkasm.push_back("iconst " + b.second + " " + b.first.first);
                    stkasm.push_back("iconst " + b.second + " " + b.first.first);
                    stkasm.push_back("iadd");
                    stkasm.push_back("iadd");
                    stkasm.push_back("iadd");

                    stkasm.push_back("iadd");
                    // stkasm.push_back("pop pointer 0");
                    // stkasm.push_back("pop that 0 " + tac[i][6]);
                }
                // ARRAY READ  t5 = arr[c]
                else if(tac[i][3] == "["){
                    // @t5 = arr [ c ] INT
                    auto a = get_type(tac[i][0], tac[i][6]);
                    auto b = get_type(tac[i][4], "INT");

                    stkasm.push_back("iconst constant " + local[tac[i][2]].first);
                    stkasm.push_back("iconst constant " + local[tac[i][2]].first);
                    stkasm.push_back("iconst constant " + local[tac[i][2]].first);
                    stkasm.push_back("iconst constant " + local[tac[i][2]].first);
                    stkasm.push_back("iadd");
                    stkasm.push_back("iadd");
                    stkasm.push_back("iadd");
                    stkasm.push_back("iconst " + b.second + " " + b.first.first);
                    stkasm.push_back("iconst " + b.second + " " + b.first.first);
                    stkasm.push_back("iconst " + b.second + " " + b.first.first);
                    stkasm.push_back("iconst " + b.second + " " + b.first.first);
                    stkasm.push_back("iadd");
                    stkasm.push_back("iadd");
                    stkasm.push_back("iadd");

                    stkasm.push_back("iadd");
                    // stkasm.push_back("pop pointer 0");
                    stkasm.push_back("iconst that 0 " + tac[i][6]);
                    // stkasm.push_back("pop " + a.second + " " + a.first.first + " " + tac[i][6]);
                }
                // CONDITIONAL JUMP (if t0 goto L1 else goto L2)
                else{
                    // if t0 goto L1 else goto L2
                    pair<pair<string, string>, string> type_a = get_type(tac[i][1], "INT");
                    // stkasm.push_back("iconst constant 0 INT");
                    stkasm.push_back("iconst " + type_a.second + " " + type_a.first.first);
                    // stkasm.push_back("eq INT");
                    stkasm.push_back("if-jmp " + tac[i][3]);
                    stkasm.push_back("jmp " + tac[i][6]);
                }
            }
        }
    }
}

void print_stkasm(){
    for (const string &h : headervec) {
        cout << h << endl;
    }

    for(int i=0; i<stkasm.size(); i++){
        if(stkasm[i].substr(0,8) == "function"){
            vector<string> temp;
            temp = tokenize(stkasm[i]);
            cout << temp[0] + " " + temp[1] + " " + to_string(fun_var_count[temp[1]].first) + " " + to_string(fun_var_count[temp[1]].second) << " " << temp[2] << endl;
        }
        else
            cout << stkasm[i] << endl;
    }
}

void header() {
    headervec.push_back(".text");
    for(int i=0; i<tac.size(); i++){
        //-----------------------------------------
        // HANDLE NON-LABEL TAC INSTRUCTIONS
        //-----------------------------------------
        if(tac[i].size() > 1){
            // CASE 1: TWO-TOKEN LINES
            if(tac[i].size() == 2){
                // FUNCTION HEADER (e.g. main: INT)
                if(tac[i][0][tac[i][0].size()-1] == ':'){
                    string func_label = tac[i][0];
                    string func_name = func_label.substr(0, func_label.size() - 1);
                    if (headerSet.insert(func_name).second) {  // inserted new
                        headervec.push_back(".global " + func_name);
                    }
                }
            }
            if(tac[i].size() == 6){
                if(tac[i][2] == "@call"){
                    string called_func = tac[i][3];  // "output" in this case
                    if (headerSet.insert(called_func).second) {  // inserted new
                        headervec.push_back(".global " + called_func);
                    }
                }
            }
        }
    }
}

int main(){
    fstream newfile;
    newfile.open("tac.txt",ios::in);
    if (newfile.is_open()){
        string tp;
        while(getline(newfile, tp)){
            vector<string> temp;
            temp = tokenize(tp);
            tac.push_back(temp);
        }
        newfile.close();
    }
    // print();
    initialize();
    header();
    conversion();
    print_stkasm();

}