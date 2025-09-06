# Makefile for MIPS Compiler Project (Flex Lexer + Bison Parser)

# Compiler and tools
CXX = g++
LEX = flex
YACC = bison

# Source files
LEX_FILE = lexer.l
YACC_FILE = parser.y

# Generated files
LEX_OUTPUT = lex.yy.c
YACC_OUTPUT = parser.tab.c
YACC_HEADER = parser.tab.h

# Executable
EXEC = compiler

# Default target
all: $(EXEC)

# Build final compiler
$(EXEC): $(LEX_OUTPUT) $(YACC_OUTPUT)
	$(CXX) $(LEX_OUTPUT) $(YACC_OUTPUT) -o $(EXEC)

# Generate C source from lex
$(LEX_OUTPUT): $(LEX_FILE) $(YACC_HEADER)
	$(LEX) $(LEX_FILE)

# Generate parser files from yacc
$(YACC_OUTPUT) $(YACC_HEADER): $(YACC_FILE)
	$(YACC) -d $(YACC_FILE)

# Run lexer+parser on input file and save output
run: $(EXEC)
	./$(EXEC) < $(FILE) > output.txt
	@echo "Parsing result stored in output.txt"

# Clean build artifacts
clean:
	rm -f $(LEX_OUTPUT) $(YACC_OUTPUT) $(YACC_HEADER) $(EXEC) output.txt

.PHONY: all run clean
