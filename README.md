# MIPS_Compiler_Design
## How to Run-
```bash
make fname=test    # Run lexer on sample programs
./parser <inpput_file>      # eg. `./parser inp1`
make clean      # Clean build artifacts
```
> **NOTE of Versions:**
>  - flex 2.6.4
>  - bison++ Version 1.21.9-1

**NOTE of inputs:** 
  - inp1 is for associativity check
  - inp2 is for if and nested-if
  - inp3 is for scope check

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

## PFA-
### 🔹 Associativity
<p align="center">
  <img src="https://github.com/user-attachments/assets/6335909a-ecc1-4851-ba73-aa64442dc286" alt="Associativity" width="800" />
</p>

### 🔹 If and Nested-If
<p align="center">
  <img src="https://github.com/user-attachments/assets/c78e705e-6fa5-4bf3-9eaa-4139d3add86a" alt="If and Nested-If" width="800" />
</p>

### 🔹 Scoping
<p align="center">
  <img src="https://github.com/user-attachments/assets/5e637590-ccbe-42af-937c-aa2efd72e10e" alt="Scoping" width="800" />
</p>
