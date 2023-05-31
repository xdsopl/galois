
SWIFT = swiftc
FLAGS = -assert-config Debug -Ounchecked

testbench: testbench.swift libGalois.a
	$(SWIFT) $(FLAGS) -I. -L. -lGalois -o $@ $<

libGalois.a: Galois/*.swift
	$(SWIFT) $(FLAGS) -static -emit-library -emit-module -module-name Galois -o $@ $^

.PHONY: test
test: testbench
	./testbench

.PHONY: clean
clean:
	rm -f testbench *.swiftdoc *.swiftmodule *.swiftsourceinfo *.a

