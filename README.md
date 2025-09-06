# MIPS_Compiler_Design

## Module 1 - Language Specification & Prototype
### Overview
- Defined KIK language basics and wrote 2 sample programs:
  - Floor & Ceil of a floating-point number
  - Prime number check
- Explored Lex (Flex) and Yacc (Bison) for compiler construction.
- Built a prototype lexer & parser that can successfully compile these programs.

### Tools
- Flex – lexical analysis
- Bison – parsing
- g++ – compilation & linking
  
### How to Run-
```bash
flex lexical_analyzer.l
bison -d parser.y
g++ lex.yy.c parser.tab.c -o kik_compiler
./kik_compiler < sample_code1.kik
./kik_compiler < sample_code2.kik
```

### Contributions
- Sai Kowshik – Language spec, sample programs, grammar draft
- Akshatha – Lexer rules, integration, build setup
- Akash – Parser rules, testing with sample programs

### Deliverables
- Draft language specification
- 2 sample KIK programs
- Working lexer + parser prototype


---


## Module 2 - Lexical Analysis (Lexer)
### Overview
- Implement a lexer for the KIK language
- Recognize keywords, identifiers, numbers, operators, and delimiters
- Skip whitespace and comments
- Output the list of tokens for a given program

### Work Done
- Wrote a Flex file (lexical_analyzer.l) defining regex patterns for tokens
- Compiled the lexer and tested with sample KIK programs
- Verified that the tokens printed match the source program structure
- Added a Makefile to automate build and run steps

### Tools
- Flex – for generating the scanner
- g++ – for compiling the generated code
- Makefile – for automating compilation and execution
  
### How to Run-
```bash
make      # Build the lexer
make run FILE=sample_code1.kik    # Run lexer on sample programs
make run FILE=sample_code2.kik
cat output.txt      # Check results
make clean      # Clean build artifacts
```

### Contributions
- Akshatha – Implemented lexer rules in Flex, integrated build
- Akash – Helped refine token categories, tested with sample programs
- Sai Kowshik – Verified token output and cross-checked with language spec draft and integrated build.

### Deliverables
- lexical_analyzer.l – KIK lexer implementation
- Makefile – Automates build and execution of lexer
- Tokenized output for sample programs


---

## Module 3 - Parser

### Work Done
- Implemented lexer.l in Flex to tokenize KIK programs.
- Created parser.y in Bison with basic grammar rules.
- Integrated lexer and parser with error reporting.
- Added a Makefile for automated build, run, and clean.

### How to Run-
```bash
make      # Build the lexer
make run FILE=sample_code1.kik    # Run lexer on sample programs
make run FILE=sample_code2.kik
cat output.txt      # Check results
make clean      # Clean build artifacts
```

### Contributions
- Akshatha: Lexical Analysis
  - Coding: Maintain lexer.l, ensure all tokens (keywords, operators, literals) are handled.
  - Reading: Study Flex manual (rules, regex, patterns). Document token definitions for the team.
  - Planning: Create a token map (language construct → token name) and keep it updated as grammar evolves.

- Akash: Parser & Grammar
  - Coding: Develop parser.y rules for statements (if, for, while, io).
  - Reading: Study Bison manual, especially handling shift/reduce conflicts (if-else).
  - Planning: Maintain a grammar document explaining each rule and its example usage in .kik code.

- Sai Kowshik: Integration & Testing
  - Coding: Write test programs (sample_code1.kik, sample_code2.kik …) to cover different grammar rules.
  - Reading: Research compiler phases (lexing, parsing, semantic analysis) and document next steps for project.
  - Planning: Set up test plan (what constructs to test, expected vs. actual parsing output).

### Deliverables
- lexer.l – Flex-based lexer for tokenizing KIK programs.
- parser.y – Bison-based parser with basic grammar rules.
- Makefile – Automates build, run, and clean operations.
- Output files – Tokenized and parsed results for sample KIK programs.

 ---
