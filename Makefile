# Default input file
INPUT ?= bundle

# Directory where .kik files live
SRC_DIR = sample_test_codes

# Output directory for generated files
OUT_DIR = output
$(shell mkdir -p $(OUT_DIR))

all: parser vm stkasm

run: parser vm stkasm
	./parser < $(SRC_DIR)/$(INPUT).kik > tac.txt;\
	./tac-vm > $(INPUT).vm;\
	./tac-stkasm > $(INPUT).stkasm;\
	mkdir -p $(OUT_DIR);\
	mv tac.txt $(INPUT).vm $(INPUT).stkasm symboltable.txt $(OUT_DIR)/

stkasm: tac-other/tac-stkasm.cpp
	g++ tac-other/tac-stkasm.cpp -o tac-stkasm

vm: tac-other/tac-vm.cpp
	g++ tac-other/tac-vm.cpp -o tac-vm

parser: y.tab.c lex.yy.c y.tab.h
	g++ -w y.tab.c lex.yy.c -o parser

y.tab.c: test.y
	yacc -v -d -t -Wno-other test.y

lex.yy.c: test.l
	lex test.l
	
clean:
	rm -f parser y.tab.c lex.yy.c y.tab.h y.output a.out tac-vm tac-stkasm tac.txt *.vm symboltable.txt
	rm -f $(filter-out $(wildcard test*.stkasm), $(wildcard *.stkasm))
	rm -rf $(OUT_DIR)