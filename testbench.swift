/*
Testbench for Galois field arithmetic

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

import Dispatch
import Galois

struct Testbench<GF: GaloisField, GFR: GaloisField> {
	static func printElapsedTime(_ name: String, _ begin: UInt64, _ end: UInt64)
	{
		var elapsed = end - begin
		var unit = "n"
		if elapsed >= 100_000_000_000 {
			unit = ""
			elapsed /= 1_000_000_000
		} else if elapsed >= 100_000_000 {
			unit = "m"
			elapsed /= 1_000_000
		} else if elapsed >= 100_000 {
			unit = "u"
			elapsed /= 1_000
		}
		print("\(name): \(elapsed) \(unit)s")
	}
	static func run() {
		assert(GF.count == GFR.count)
		let size = GF.count
		let mulBegin = DispatchTime.now().uptimeNanoseconds
		for i in 0 ..< size {
			for j in 0 ..< size {
				assert((GF(i) * GF(j)).value == (GFR(i) * GFR(j)).value)
			}
		}
		let mulEnd = DispatchTime.now().uptimeNanoseconds
		printElapsedTime("mul", mulBegin, mulEnd)
		let divBegin = DispatchTime.now().uptimeNanoseconds
		for i in 0 ..< size {
			for j in 1 ..< size {
				assert((GF(i) / GF(j)).value == (GFR(i) / GFR(j)).value)
			}
		}
		let divEnd = DispatchTime.now().uptimeNanoseconds
		printElapsedTime("div", divBegin, divEnd)
		let rcpBegin = DispatchTime.now().uptimeNanoseconds
		for j in 1 ..< size {
			assert(GF(j).reciprocal.value == GFR(j).reciprocal.value)
		}
		let rcpEnd = DispatchTime.now().uptimeNanoseconds
		printElapsedTime("rcp", rcpBegin, rcpEnd)
	}
}
struct PrimitivePolynomial19: PrimitivePolynomial {
	typealias type = UInt8
	static let poly = 19
}
struct PrimitivePolynomial285: PrimitivePolynomial {
	typealias type = UInt8
	static let poly = 285
}
struct PrimitivePolynomial16427: PrimitivePolynomial {
	typealias type = UInt16
	static let poly = 16427
}
struct PrimitivePolynomial69643: PrimitivePolynomial {
	typealias type = UInt16
	static let poly = 69643
}
struct PrimitivePolynomial4299161607: PrimitivePolynomial {
	typealias type = UInt32
	static let poly = 4299161607
}
print("exhaustive test for GF(2^4):")
GF8.generateTables(19)
Testbench<GF8, GaloisFieldReference<PrimitivePolynomial19>>.run()
print("exhaustive test for GF(2^8):")
GF8.generateTables(285)
Testbench<GF8, GaloisFieldReference<PrimitivePolynomial285>>.run()
GF8.destroyTables()
print("exhaustive test for GF(2^14) (takes a minute to complete):")
GF16.generateTables(16427)
Testbench<GF16, GaloisFieldReference<PrimitivePolynomial16427>>.run()
print("exhaustive test for GF(2^16) (be patient, takes minutes to complete):")
GF16.generateTables(69643)
Testbench<GF16, GaloisFieldReference<PrimitivePolynomial69643>>.run()
GF16.destroyTables()

