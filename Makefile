
SWIFT = swiftc
FLAGS = -assert-config Debug -Ounchecked

.PHONY: all
all: testbench lagrange cauchy

testbench: testbench.swift libGalois.a
	$(SWIFT) $(FLAGS) -I. -L. -lGalois -o $@ $<

lagrange: lagrange.swift libGalois.a
	$(SWIFT) $(FLAGS) -I. -L. -lGalois -o $@ $<

cauchy: cauchy.swift libGalois.a
	$(SWIFT) $(FLAGS) -I. -L. -lGalois -o $@ $<

libGalois.a: Galois/*.swift
	$(SWIFT) $(FLAGS) -static -emit-library -emit-module -module-name Galois -o $@ $^

.PHONY: test
test: lagrange cauchy testbench
	./lagrange
	./cauchy
	./testbench

.PHONY: clean
clean:
	rm -f lagrange cauchy testbench *.abi.json *.swiftdoc *.swiftmodule *.swiftsourceinfo *.a

