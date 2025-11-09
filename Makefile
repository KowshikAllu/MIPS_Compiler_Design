# Default input file
ip ?= bundle

# Directory where .kik files live
SRC_DIR = sample_test_codes

# Output directory for generated files
OUT_DIR = output
$(shell mkdir -p $(OUT_DIR))

all: parser vm stkasm stkasm_orig

# run:
# 	./parser < $(SRC_DIR)/$(ip).kik > tac.txt;\
# 	./tac-vm > output.vm;\
# 	./tac-stkasm > output.stkasm;\
# 	mkdir -p $(OUT_DIR)/$(ip);\
# 	mv tac.txt output.vm output.stkasm FunctionTable.txt ClassTable.txt $(OUT_DIR)/$(ip)/

run:
	./parser < $(SRC_DIR)/$(ip).kik > tac.txt;\
	./tac-vm > output.vm;\
	./tac-stkasm_orig;\
	./tac-stkasm;\
	mkdir -p $(OUT_DIR);\
	mv tac.txt output.vm output_orig.stkasm output.stkasm FunctionTable.txt ClassTable.txt $(OUT_DIR)/

stkasm_orig: tac-other/tac-stkasm_orig.cpp
	g++ tac-other/tac-stkasm_orig.cpp -o tac-stkasm_orig

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
	rm -rf $(OUT_DIR)

clean-all:
	rm -f parser y.tab.c lex.yy.c y.tab.h y.output *.exe
	rm -rf $(OUT_DIR)