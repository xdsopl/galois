
SWIFT = swiftc
FLAGS = -assert-config Debug -Ounchecked

.PHONY: all
all: testbench example

testbench: testbench.swift libGalois.a
	$(SWIFT) $(FLAGS) -I. -L. -lGalois -o $@ $<

example: example.swift libGalois.a
	$(SWIFT) $(FLAGS) -I. -L. -lGalois -o $@ $<

libGalois.a: Galois/*.swift
	$(SWIFT) $(FLAGS) -static -emit-library -emit-module -module-name Galois -o $@ $^

.PHONY: test
test: example testbench
	./example
	./testbench

.PHONY: clean
clean:
	rm -f example testbench *.abi.json *.swiftdoc *.swiftmodule *.swiftsourceinfo *.a

