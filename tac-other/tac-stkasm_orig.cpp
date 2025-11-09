#include <iostream>
#include <fstream>
#include <string>
#include <regex>
#include <unordered_map>
#include <sstream>

using namespace std;

// Function to trim whitespace from both ends of a string
string trim(const string &s) {
    string out = s;
    size_t start = out.find_first_not_of(" \t\r\n");
    size_t end = out.find_last_not_of(" \t\r\n");
    if (start == string::npos) return "";
    return out.substr(start, end - start + 1);
}

int main() {
    // NOTE: This assumes your TAC is in 'tac.txt'
    ifstream tacFile("tac.txt");
    ofstream stkFile("output_orig.stkasm");

    if (!tacFile.is_open()) {
        cerr << "Error: Could not open tac.txt. Ensure the file exists.\n";
        return 1;
    }

    stkFile << "# Auto-generated .stkasm from TAC\n";
    stkFile << ".text\n";
    
    string line;
    // Stores constant values for temporaries, e.g., @t1 -> "0"
    unordered_map<string, string> tempValues; 
    smatch matches; // For regex results

    while (getline(tacFile, line)) {
        line = trim(line);
        
        // Skip empty lines and full-line comments (but not labels)
        if (line.empty() || (line[0] == '#' && line.find("#L") != 0))
            continue;

        // --- Function/Method Definition (Label and Global Export) ---
        // func: void OR kik: INT
        if (regex_match(line, matches, regex("([a-zA-Z_][a-zA-Z0-9_]*): (INT|void)"))) {
            string func_name = matches[1];
            stkFile << "\n.global " << func_name << "\n";
            stkFile << func_name << ":\n";
            continue;
        }

        // --- Unary Operator (Logical NOT ~) ---
        // @t9 = ~ @t10 INT
        if (regex_match(line, matches, regex("(@t[0-9]+) = ~ (@t[0-9]+) INT"))) {
            string rhs = matches[2]; // The temporary variable being negated

            // Load the temporary value onto the stack
            if (tempValues.count(rhs)) {
                stkFile << "    iconst " << tempValues[rhs] << "\n";
            } 
            
            stkFile << "    inot\n"; // Pushes 0 if input was 1, and 1 if input was 0
            continue;
        }

        // --- Label ---
        // #L0:
        if (line.find("#L") == 0 && line.find(":") != string::npos) {
            stkFile << line << "\n";
            continue;
        }

        // --- Constant Assignment ---
        // @t0 = 2 INT (Value is stored in the map)
        if (regex_match(line, matches, regex("(@t[0-9]+) = ([0-9]+) INT"))) {
            string name = matches[1];
            string val = matches[2];
            tempValues[name] = val;
            continue;
        }

        //!! --- Array Declaration (Allocation and Initialization) ---
        // - INT numbers [ 5 ]
        // if (regex_match(line, matches, regex("- INT ([a-zA-Z_][a-zA-Z0-9_]*) \\[ ([0-9]+) \\]"))) {
        //     string arr_name = matches[1];
        //     string arr_size = matches[2];

        //     stkFile << "    iconst " << arr_size << "\n";      // 1. Push array size (e.g., 5)
        //     stkFile << "    newarray INT\n";                 // 2. Allocate and initialize all elements to 0
        //     stkFile << "    astore " << arr_name << "\n";    // 3. Store the array reference in the local variable
        //     continue;
        // }

        // --- Array Initialization (iastore) ---
        // numbers [ 0 ] = 4 INT
        if (regex_match(line, matches, regex("([a-zA-Z_][a-zA-Z0-9_]*) \\[ ([0-9]+) \\] = ([0-9]+) INT"))) {
            string arr_name = matches[1];
            string index = matches[2];
            string val = matches[3];
            // Stack order for iastore: [reference, index, value]
            stkFile << "    iconst " << val << "\n";    // Push value
            stkFile << "    iconst " << index << "\n";  // Push index
            stkFile << "    iastore " << arr_name << "\n"; // Store value at index
            continue;
        }
        
        // --- Array Access (iaload) ---
        // @t5 = numbers [ i ] INT
        if (regex_match(line, matches, regex("(@t[0-9]+) = ([a-zA-Z_][a-zA-Z0-9_]*) \\[ ([a-zA-Z_][a-zA-Z0-9_]*) \\] INT"))) {
            string arr_name = matches[2];
            string index_var = matches[3];
            
            stkFile << "    iload " << index_var << "\n";   // Push index (e.g., value of i)
            stkFile << "    iaload " << arr_name << "\n";  // Pop index, push value from array
            continue; 
        }

        // --- Arithmetic/Comparison Operations (Extended to include Modulo %) ---
        // @t2 = i < @t1 INT
        // @t4 = i + @t3 INT
        // @t7 = number % i INT  <-- NEW
        if (regex_match(line, matches, regex("(@t[0-9]+) = (.+) (\\+|\\<|%) (.+) INT"))) { // <--- Added '|%'
            string a = trim(matches[2]);
            string op = trim(matches[3]);
            string b = trim(matches[4]);

            // ... [Code for Operand 1 (a) and Operand 2 (b) remains the same] ...
            // Operand 1 (a)
            if (tempValues.count(a)) {
                stkFile << "    iconst " << tempValues[a] << "\n";
            } else {
                stkFile << "    iload " << a << "\n";
            }

            // Operand 2 (b)
            if (tempValues.count(b)) {
                stkFile << "    iconst " << tempValues[b] << "\n";
            } else {
                stkFile << "    iload " << b << "\n";
            }

            // Operation (Extended)
            if (op == "+") stkFile << "    iadd\n";
            if (op == "<") stkFile << "    ilt\n";
            if (op == "%") stkFile << "    imod\n";
            if (op == "==") stkFile << "    ieq\n";
            
            continue;
        }

        // --- Variable Assignment (istore) ---
        // i = @t0 INT 
        if (regex_match(line, matches, regex("([a-zA-Z_][a-zA-Z0-9_]*) = (@t[0-9]+) INT"))) {
            string lhs = matches[1];
            string rhs = matches[2];

            if (tempValues.count(rhs)) {
                // Assignment from a *constant* temporary
                stkFile << "    iconst " << tempValues[rhs] << "\n";
            } 
            // If not a constant temp, the value is already on the stack from a previous operation.
            
            stkFile << "    istore " << lhs << "\n"; // Pop value from stack, store in var
            continue;
        }

        // --- String Assignment (s = "kik code" STR) ---
        if (regex_match(line, matches, regex("([a-zA-Z_][a-zA-Z0-9_]*) = \"(.*)\" STR"))) {
            string lhs = matches[1];
            string val = matches[2];
            stkFile << "    sconst \"" << val << "\"\n"; // Push string reference
            stkFile << "    sstore " << lhs << "\n";      // Store reference in variable 's'
            continue;
        }

        // --- Conditional jump (jnz/jmp) ---
        // if : GOTO #L1 else GOTO #L2
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
        // param "Numbers are: " string
        if (line.find("param \"") != string::npos) {
            size_t first = line.find("\"");
            size_t last = line.find_last_of("\"");
            string str = line.substr(first, last - first + 1);
            stkFile << "    sconst " << str << "\n";
            continue;
        }
        
        // --- Param (Variable) ---
        // param number INT (Push variable value as argument)
        if (regex_match(line, matches, regex("param ([a-zA-Z_][a-zA-Z0-9_]*) INT"))) {
            stkFile << "    iload " << matches[1] << "\n"; 
            continue;
        }
        
        // --- Param (Temporary) ---
        // param @t5 INT (Value is already on the stack)
        if (regex_match(line, regex("param @t[0-9]+ INT"))) {
            continue;
        }

        // --- Function/Output Call (invoke) ---
        // @t1 = @call func void 2 OR @t0 = @call output VOID 1
        // Assumes arguments have already been pushed via 'param' instructions
        if (regex_match(line, matches, regex("(@t[0-9]+)? = @call ([a-zA-Z_][a-zA-Z0-9_]*) (INT|void) ([0-9]+)"))) {
            string func_name = matches[2];
            string arg_count = matches[4];
            
            stkFile << "    invoke " << func_name << " " << arg_count << "\n";
            continue;
        }

        // --- Unconditional jump (jmp) ---
        // GOTO #L3
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

            // UPDATED: Check if the return value is a known constant temporary
            if (tempValues.count(val_ref)) {
                // Case 1: Returning a constant (e.g., return @t1 where @t1=0)
                stkFile << "    iconst " << tempValues[val_ref] << "\n";
            } else {
                // Case 2: Returning a computed value (e.g., return @t0 where @t0=a+b)
                // The value is already on the stack from the previous 'iadd' or 'invoke'.
                // Do nothing.
            }
            stkFile << "    ret\n";
            continue;
        }

        // --- Skip declarations (INT, arg INT, STR) and end tag ---
        if (regex_match(line, regex("- (INT|arg INT|STR) [a-zA-Z_][a-zA-Z0-9_]*(\\[ [0-9]+ \\])?")) || line == "end:") {
            continue; 
        }

        // --- Debug: Log unhandled lines ---
        cerr << "Warning: Unhandled TAC line: " << line << "\n";
    }

    tacFile.close();
    stkFile.close();

    cout << "✅ STKASM code generator completed. Output written to 'output_orig.stkasm'.\n";
    cout << "===========================================================================\n";
    return 0;
}