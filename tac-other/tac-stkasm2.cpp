#include <bits/stdc++.h>
using namespace std;

// Function to trim whitespace from both ends of a string
string trim(const string &s) {
    string out = s;
    size_t start = out.find_first_not_of(" \t\r\n");
    size_t end = out.find_last_not_of(" \t\r\n");
    if (start == string::npos) return "";
    return out.substr(start, end - start + 1);
}

// FIXED: Helper function to check if a string is a number
bool is_number(const string& s) {
    return !s.empty() && find_if(s.begin(), s.end(), [](unsigned char c) { return !isdigit(c); }) == s.end();
}

int main() {
    ifstream tacFile("tac.txt");
    ofstream stkFile("output.stkasm");

    if (!tacFile.is_open()) {
        cerr << "Error: Could not open tac.txt. Ensure the file exists.\n";
        return 1;
    }

    stkFile << "# Auto-generated .stkasm from TAC\n";
    stkFile << ".text\n";
    
    string line;
    unordered_map<string, string> tempValues; 
    smatch matches; 

    unordered_map<string, int> varIndex;
    int nextVarIndex = 0;

    while (getline(tacFile, line)) {
        line = trim(line);
        
        if (line.empty() || (line[0] == '#' && line.find("#L") != 0))
            continue;

        // --- Function/Method Definition (Label and Global Export) ---
        if (regex_match(line, matches, regex("([a-zA-Z_][a-zA-Z0-9_]*): (INT|void|VOID)"))) {
            string func_name = matches[1];
            stkFile << "\n.global " << func_name << "\n";
            stkFile << func_name << ":\n";
            
            varIndex.clear();
            nextVarIndex = 0;
            
            continue;
        }

        // --- Argument Declaration ---
        // - arg INT number
        if (regex_match(line, matches, regex("- arg (INT|STR) ([a-zA-Z_][a-zA-Z0-9_]*)"))) {
            string var_name = matches[2];
            if (varIndex.find(var_name) == varIndex.end()) {
                varIndex[var_name] = nextVarIndex++;
            }
            continue; 
        }

        // --- Variable Declaration ---
        // - INT result
        if (regex_match(line, matches, regex("- (INT|STR) ([a-zA-Z_][a-zA-Z0-9_]*)"))) {
            string var_name = matches[2];
            if (varIndex.find(var_name) == varIndex.end()) {
                varIndex[var_name] = nextVarIndex++;
            }
            continue; 
        }

        // --- Array Declaration (Allocation and Initialization) ---
        // - INT numbers [ 5 ]
        if (regex_match(line, matches, regex("- INT ([a-zA-Z_][a-zA-Z0-9_]*) \\[ ([0-9]+) \\]"))) {
            string arr_name = matches[1];
            string arr_size = matches[2];

            if (varIndex.find(arr_name) == varIndex.end()) {
                varIndex[arr_name] = nextVarIndex++;
            }
            
            stkFile << "    iconst " << arr_size << "\n";
            stkFile << "    newarray INT\n"; 
            stkFile << "    astore " << varIndex[arr_name] << "\n"; // Use index
            continue;
        }

        // --- Unary Operator (Logical NOT ~) ---
        if (regex_match(line, matches, regex("(@t[0-9]+) = ~ (@t[0-9]+) INT"))) {
            string rhs = matches[2]; 
            if (tempValues.count(rhs)) {
                stkFile << "    iconst " << tempValues[rhs] << "\n";
            } 
            stkFile << "    inot\n"; 
            continue;
        }

        // --- Label ---
        if (line.find("#L") == 0 && line.find(":") != string::npos) {
            stkFile << line << "\n";
            continue;
        }

        // --- Constant Assignment ---
        if (regex_match(line, matches, regex("(@t[0-9]+) = ([0-9]+) INT"))) {
            string name = matches[1];
            string val = matches[2];
            tempValues[name] = val;
            continue;
        }

        // --- Array Initialization (iastore) ---
        if (regex_match(line, matches, regex("([a-zA-Z_][a-zA-Z0-9_]*) \\[ ([0-9]+) \\] = ([0-9]+) INT"))) {
            string arr_name = matches[1];
            string index = matches[2];
            string val = matches[3];
            
            stkFile << "    aload " << varIndex[arr_name] << "\n";
            stkFile << "    iconst " << index << "\n"; 
            stkFile << "    iconst " << val << "\n";    
            stkFile << "    iastore\n"; 
            continue;
        }
        
        // --- Array Access (iaload) ---
        // FIXED: Regex to allow multi-character variable names
        if (regex_match(line, matches, regex("(@t[0-9]+) = ([a-zA-Z_][a-zA-Z0-9_]*) \\[ ([a-zA-Z_][a-zA-Z0-9_]*) \\] INT"))) {
            string arr_name = matches[2];
            string index_var = matches[3];
            
            stkFile << "    aload " << varIndex[arr_name] << "\n"; 
            stkFile << "    iload " << varIndex[index_var] << "\n"; 
            stkFile << "    iaload\n"; 
            continue; 
        }

        // --- Arithmetic/Comparison Operations ---
        if (regex_match(line, matches, regex("(@t[0-9]+) = (.+) (\\+|\\<|%|==) (.+) INT"))) { 
            string a = trim(matches[2]);
            string op = trim(matches[3]);
            string b = trim(matches[4]);

            // --- Handle Operand 1 (a) ---
            if (a.rfind("@t", 0) == 0) {
                // It's a temporary (e.g., @t2), value is already on stack.
                // But if it's a CONSTANT temporary, we need to push it.
                if (tempValues.count(a)) {
                    stkFile << "    iconst " << tempValues[a] << "\n";
                }
            } else if (is_number(a)) { // FIXED: Check if it's a raw number
                stkFile << "    iconst " << a << "\n";
            } else {
                // It's a variable
                stkFile << "    iload " << varIndex[a] << "\n"; // Use index
            }

            // --- Handle Operand 2 (b) ---
            if (b.rfind("@t", 0) == 0) {
                // It's a temporary (e.g., @t3), value is already on stack.
                if (tempValues.count(b)) {
                    stkFile << "    iconst " << tempValues[b] << "\n";
                }
            } else if (is_number(b)) { // FIXED: Check if it's a raw number
                stkFile << "    iconst " << b << "\n";
            } else {
                // It's a variable
                stkFile << "    iload " << varIndex[b] << "\n"; // Use index
            }

            // --- Operation ---
            if (op == "+") stkFile << "    iadd\n";
            if (op == "<") stkFile << "    ilt\n";
            if (op == "%") stkFile << "    imod\n";
            if (op == "==") stkFile << "    ieq\n";
            
            continue;
        }

        // --- Variable Assignment (istore) ---
        if (regex_match(line, matches, regex("([a-zA-Z_][a-zA-Z0-9_]*) = (@t[0-9]+) INT"))) {
            string lhs = matches[1];
            string rhs = matches[2];

            if (tempValues.count(rhs)) {
                stkFile << "    iconst " << tempValues[rhs] << "\n";
            } 
            
            if (varIndex.find(lhs) == varIndex.end()) {
                 varIndex[lhs] = nextVarIndex++;
            }
            stkFile << "    istore " << varIndex[lhs] << "\n"; 
            continue;
        }

        // --- String Assignment (s = "kik code" STR) ---
        // FIXED: Regex to allow multi-character var names and full strings
        if (regex_match(line, matches, regex("([a-zA-Z_][a-zA-Z0-9_]*) = \"(.*)\" STR"))) {
            string lhs = matches[1];
            string val = matches[2];
            stkFile << "    sconst \"" << val << "\"\n"; 
            
            if (varIndex.find(lhs) == varIndex.end()) {
                 varIndex[lhs] = nextVarIndex++;
            }
            stkFile << "    sstore " << varIndex[lhs] << "\n";       
            continue;
        }

        // --- Conditional jump (jnz/jmp) ---
        if (line.find("if : GOTO") != string::npos) {
            size_t firstGoto = line.find("GOTO") + 5;
            size_t elsePos = line.find("else GOTO");
            string trueLabel = trim(line.substr(firstGoto, elsePos - firstGoto));
            string falseLabel = trim(line.substr(elsePos + 10));
            
            stkFile << "    jnz " << trueLabel << "\n"; 
            stkFile << "    jmp " << falseLabel << "\n";
            continue;
        }

        // --- Param (String) ---
        if (line.find("param \"") != string::npos) {
            size_t first = line.find("\"");
            size_t last = line.find_last_of("\"");
            string str = line.substr(first, last - first + 1);
            stkFile << "    sconst " << str << "\n";
            continue;
        }
        
        // --- Param (Variable) ---
        if (regex_match(line, matches, regex("param ([a-zA-Z_][a-zA-Z0-9_]*) INT"))) {
            stkFile << "    iload " << varIndex[matches[1]] << "\n"; 
            continue;
        }
        
        // --- Param (Temporary) ---
        if (regex_match(line, matches, regex("param (@t[0-9]+) INT"))) {
            string temp_name = matches[1]; 

            if (tempValues.count(temp_name)) {
                stkFile << "    iconst " << tempValues[temp_name] << "\n";
            } else {
                // Value is already on the stack. Do nothing.
            }
            continue;
        }

        // --- Function/Output Call (invoke) ---
        if (regex_match(line, matches, regex("(@t[0-9]+)? = @call ([a-zA-Z_][a-zA-Z0-9_]*) (INT|void|VOID) ([0-9]+)"))) {
            string func_name = matches[2];
            string arg_count = matches[4];
            
            stkFile << "    invoke " << func_name << " " << arg_count << "\n";
            continue;
        }

        // --- Unconditional jump (jmp) ---
        if (line.find("GOTO #L") != string::npos) {
            string label = trim(line.substr(line.find("GOTO") + 5));
            stkFile << "    jmp " << label << "\n";
            continue;
        }

        // --- Return ---
        if (line.find("return") != string::npos) {
            size_t pos = line.find("return");
            string val_ref = trim(line.substr(pos + 6));
            val_ref = trim(val_ref.substr(0, val_ref.find("INT")));

            if (tempValues.count(val_ref)) {
                stkFile << "    iconst " << tempValues[val_ref] << "\n";
            } else {
                // Value is already on the stack. Do nothing.
            }
            stkFile << "    ret\n";
            continue;
        }

        // --- Skip end tag ---
        if (line == "end:") {
            continue; 
        }

        // --- Debug: Log unhandled lines ---
        cerr << "Warning: Unhandled TAC line: " << line << "\n";
    }

    tacFile.close();
    stkFile.close();

    cout << "✅ STKASM code generator updated successfully.\n";
    return 0;
}


// Arrays proper