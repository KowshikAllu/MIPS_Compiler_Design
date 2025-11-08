# Default input file
INPUT ?= bundle

# Directory where .kik files live
SRC_DIR = sample_test_codes

# Output directory for generated files
OUT_DIR = output
$(shell mkdir -p $(OUT_DIR))

all: parser

run:
	./parser < $(SRC_DIR)/$(INPUT).kik > tac.txt;\
	./tac-vm > $(INPUT).vm;\
	./tac-stkasm > $(INPUT).stkasm;\
	./tac-stkasm2 > $(INPUT).stkasm2;\
	mkdir -p $(OUT_DIR);\
	mv tac.txt $(INPUT).vm $(INPUT).stkasm output.stkasm $(INPUT).stkasm2 FunctionTable.txt ClassTable.txt $(OUT_DIR)/

stkasm2: tac-other/tac-stkasm2.cpp
	g++ tac-other/tac-stkasm2.cpp -o tac-stkasm2

stkasm: tac-other/tac-stkasm.cpp
	g++ tac-other/tac-stkasm.cpp -o tac-stkasm

vm: tac-other/tac-vm.cpp
	g++ tac-other/tac-vm.cpp -o tac-vm

parser: y.tab.c lex.yy.c y.tab.h
	g++ -w y.tab.c lex.yy.c -o parser

y.tab.c: test.y
	yacc -v -d -t -Wno-other test.y -Wcounterexamples

lex.yy.c: test.l
	lex test.l
	
clean:
	rm -rf $(OUT_DIR)

clean-all:
	rm -f parser y.tab.c lex.yy.c y.tab.h y.output a.out tac-vm tac-stkasm tac.txt *.vm FunctionTable.txt ClassTable.txt
	rm -f $(filter-out $(wildcard test*.stkasm), $(wildcard *.stkasm))
	rm -f $(filter-out $(wildcard test*.stkasm2), $(wildcard *.stkasm2))
	rm -rf $(OUT_DIR)