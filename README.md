# MIPS_Compiler_Design

### Prerequisites-
- Flex, Bison and g++ Installed
  
### Commands to Run-
```bash
flex lexical_analyzer.y
bison -d parser.y
g++ lex.yy.c parser.tab.c -o kik_compiler
./kik_compiler < sample_code1.kik
```
