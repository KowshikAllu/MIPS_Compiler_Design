# Makefile for MIPS Compiler Project (Flex Lexer)

# Compiler and tools
CXX = g++
LEX = flex

# Files
LEX_FILE = lexical_analyzer.l
LEX_OUTPUT = lex.yy.c
EXEC = lexer

# Default target
all: $(EXEC)

# Build lexer from lex file
$(EXEC): $(LEX_OUTPUT)
	$(CXX) $(LEX_OUTPUT) -o $(EXEC)

# Generate C file from lex
$(LEX_OUTPUT): $(LEX_FILE)
	$(LEX) $(LEX_FILE)

# Run lexer on input file and save output to output.txt
run: $(EXEC)
	./$(EXEC) < $(FILE) > output.txt
	@echo "Token output stored in output.txt"

# Clean build artifacts
clean:
	rm -f $(LEX_OUTPUT) $(EXEC) output.txt

.PHONY: all run clean
