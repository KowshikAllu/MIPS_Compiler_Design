# MIPS_Compiler_Design
## How to Run-
```bash
make run
make run INPUT=example
make clean
make clean-all
```
> **NOTE of Versions:**
>  - flex 2.6.4
>  - bison++ Version 1.21.9-1

**NOTE of inputs:** 
  - Find inputs in `sample_test_codes` folder
  - Find output in `output` folder

---

## Module 1 - Language Specification & Prototype [Date: 24th Aug, 2025]
### Overview
- Defined KIK language basics and wrote 2 sample programs:
  - Floor & Ceil of a floating-point number
  - Prime number check
- Explored Lex (Flex) and Yacc (Bison) for compiler construction.
- Built a prototype lexer & parser that can successfully compile these programs.

### Tools
- Flex – lexical analysis
- Bison – parsing
- gcc – compilation & linking
- Makefile – for automating compilation and execution

### Contributions
- Sai Kowshik – Language spec, sample programs, grammar draft
- Akshatha – Lexer rules, integration, build setup
- Akash – Parser rules, testing with sample programs

### Deliverables
- Draft language specification
- 2 sample KIK programs
- Working lexer + parser prototype


---


## Module 2 - Lexical & Syntax Analysis [Date: 30th Aug, 2025]
### Overview
This module is the front-end of the compiler. It scans the input source code and converts it into tokens using lexical rules. Then, the syntax analyzer checks if the sequence of tokens follows the defined grammar rules. If the input is syntactically correct, a parse tree is generated.

### Work Done
- Designed and implemented the lexical analyzer using Lex/Flex.
- Defined tokens: identifiers, operators, keywords, numbers, etc.
- Implemented context-free grammar (CFG) in Yacc for expressions, conditions, loops, and assignments.
- Handled operator precedence and associativity in grammar.
- Constructed parse tree/syntax tree for valid inputs.
- Resolved shift/reduce conflicts during parser generation.
- Tested with basic input files (arithmetic expressions, if-else, while).

### Contributions
- Akshatha:
  - Designed and implemented the lexical analyzer (Flex/Lex).
  - Defined regex rules for identifiers, numbers, operators, keywords.
  - Generated tokens (VAR, PLUS, MINUS, MUL, DIV, INC, DEC, IF, ELSE, etc.).
- Akash:
  - Worked on Yacc grammar design (CFG).
  - Defined production rules for expressions, conditions, and loops.
  - Implemented parse-tree generation and basic error recovery rules.
- Sai Kowshik:
  - Integrated Lex and Yacc modules.
  - Debugged shift/reduce conflicts in grammar.
  - Tested the parser with basic input programs and ensured correct token-to-syntax mapping.
  
---

## Module 3 - Basic TAC Generation & Symbol Table [Date: 6th Sep, 2025]

### Overview
Once the syntax is validated, the next step is to produce an intermediate representation (IR) of the program. We used Three Address Code (TAC) for this. The symbol table keeps track of identifiers, types, sizes, and memory offsets. Together, these allow translation into machine-understandable form in later stages.

### Work Done
- Implemented TAC generation for arithmetic, relational, and logical operations.
- Added backpatching support for control flow (if, else, while).
- Defined a struct for TAC (True, False, next, lexval, code) to store intermediate results.
- Implemented label management for jumps and branching statements.
- Designed and implemented a symbol table (name, type, size, offset).
- Integrated symbol table lookup with TAC generation to validate identifiers.
- Verified TAC generation with test programs (arithmetic evaluation, nested if-else, loops).

### Contributions
- Akash:
  - Implemented TAC (Three Address Code) generation functions.
  - Handled assignment, arithmetic, relational operators.
  - Implemented backpatching for control flow (if, while).
- Akshatha:
  - Designed structs for TAC storage (True, False, next, lexval, code).
  - Managed label creation and linking for conditional jumps.
  - Extended grammar actions to generate TAC inline.
- Sai Kowshik:
  - Designed and implemented the symbol table structure.
  - Maintained entries (name, type, size, offset).
  - Added support for variable declaration & lookup in TAC generation.

---

## Module 4 - Function Implementation [Date: 15th Sep, 2025]

### Overview
Implemented the function subsystem of the KIK compiler: declaration, parameter handling, scoping, return checks, and integration with TAC generation. Added semantic checks (duplicate function names, missing return statements for non-void functions) and maintained a function table with signatures and parameter lists.

### Work Done
- Added stack frame setup and teardown for each function.
- Managed local and temporary variables separately per call.
- Enabled basic function call and return mechanism.

### Contributions
- Akash:
  - Implemented stack-based function call logic and local variable management.
- Akshatha:
  - Worked on parameter passing and return value handling in the stack frame.
- Sai Kowshik:
  - Created test programs to validate function behavior and debugged stack-related issues.

---

## Module 5 - .stkasm Generation [Date: 22nd Sep, 2025]

### Overview
Translated Three Address Code (TAC) to custom stack assembly (.stkasm) for low-level execution.

### Work Done
- Mapped TAC instructions to stack operations (iconst, istr, invoke, if-jmp, etc.).
- Implemented label handling for loops and conditionals.
- Generated separate .stkasm files for each Kik program.

### Contributions
- Akash:
  - Developed translation logic from TAC to .stkasm and verified correctness.
- Akshatha:
  - Added support for control flow and function call assembly conversion.
- Sai Kowshik:
  - Validated .stkasm output with sample programs and debugged label jumps.

---

## Module 6 - Error & Type Handling [Date: 6th Oct, 2025]

### Overview
Implemented error detection and type management in the Kik compiler to ensure code correctness and enforce language rules.

### Work Done
- Added checks for variable declarations before use.
- Detected multiple declarations of the same variable.
- Reserved keywords validation to prevent misuse as identifiers.
- Introduced type checking for expressions and assignments.
- Displayed clear error messages during parsing and semantic analysis.

### Contributions
- Akash:
  - Implemented variable declaration validation and type-checking logic.
- Akshatha:
  - Added reserved word detection and semantic error reporting.
- Sai Kowshik:
  - Tested various invalid programs to verify proper error detection and message formatting.

---

## Module 7 - TAC Optimization [Date: 18th Oct, 2025]

### Overview
Developed optimization techniques for Three Address Code (TAC) to improve execution efficiency and reduce redundant operations.

### Work Done
- Implemented label optimization to merge consecutive labels.
- Replaced redundant label references across TAC lines.
- Removed unnecessary jump targets and unused labels.
- Designed tokenization logic for parsing TAC lines.
- Verified correctness by comparing TAC before and after optimization.

### Contributions
- Akash:
  - Wrote core label optimization logic and handled TAC parsing.

- Akshatha:
  - Integrated replacement and deletion of redundant labels.

- Sai Kowshik:
  - Tested optimization results and validated correctness of transformed TAC output.

---