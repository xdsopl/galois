
SWIFT = swiftc
FLAGS = -assert-config Debug -Ounchecked

testbench: testbench.swift
	$(SWIFT) $(FLAGS) $< -o $@

.PHONY: test
test: testbench
	./testbench

.PHONY: clean
clean:
	rm -f testbench

