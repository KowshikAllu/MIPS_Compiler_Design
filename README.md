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
flex lexical_analyzer.y
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
- Wrote a Flex file (lexer.l) defining regex patterns for tokens
- Compiled the lexer and tested with sample KIK programs
- Verified that the tokens printed match the source program structure

### Tools
- Flex – for generating the scanner
- g++ – for compiling the generated code
  
### How to Run-
```bash
flex lexical_analyzer.l
g++ lex.yy.c -o lexer
./lexer < sample1.kik
./lexer < sample2.kik

```

### Contributions
- Akash – Implemented lexer rules in Flex, integrated build
- Akshatha – Helped refine token categories, tested with sample programs
- Sai Kowshik – Verified token output and cross-checked with language spec draft

### Deliverables
- lexer.l – KIK lexer implementation
- Tokenized output for sample programs


---
