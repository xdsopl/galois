/*
Galois field arithmetic

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

import Dispatch

protocol GaloisField: AdditiveArithmetic {
	associatedtype type where type: FixedWidthInteger, type: UnsignedInteger
	var value: type { get set }
	static var count: Int { get }
	static func *(left: Self, right: Self) -> Self
	static func *=(left: inout Self, right: Self)
	static func /(left: Self, right: Self) -> Self
	static func /=(left: inout Self, right: Self)
	var reciprocal: Self { get }
	init(_ value: type)
	init(_ value: Int)
}
extension GaloisField {
	static var zero: Self {
		return Self(0)
	}
	static func +(left: Self, right: Self) -> Self {
		return Self(left.value ^ right.value)
	}
	static func -(left: Self, right: Self) -> Self {
		return left + right
	}
	static func *=(left: inout Self, right: Self) {
		left = left * right
	}
	static func /=(left: inout Self, right: Self) {
		left = left / right
	}
	static func degree<T: FixedWidthInteger>(_ poly: T) -> Int {
		return poly.bitWidth - 1 - poly.leadingZeroBitCount
	}
	var description: String {
		return String(value)
	}
	init(_ value: Int) {
		self.init(type(value))
	}
}
protocol TableGeneratable {
	static func generateTables(_ poly: Int)
	static func destroyTables()
}
struct GF8: GaloisField, TableGeneratable {
	typealias type = UInt8
	var value: type
	static var mul: [[type]] = []
	static var inv: [type] = []
	static var count: Int {
		return mul.count
	}
	static func generateTables(_ poly: Int) {
		let d = degree(poly)
		assert(d <= 8)
		let size = 1 << d
		let max = size - 1
		var log = [type](repeating: 0, count: size)
		var exp = [type](repeating: 0, count: size)
		log[0] = type(max)
		exp[max] = 0
		var a = type(1)
		let p = type(truncatingIfNeeded: poly)
		for i in 0 ..< max {
			log[Int(a)] = type(i)
			exp[i] = type(a)
			if a >> (d - 1) == 1 {
				a <<= 1
				a ^= p
			} else {
				a <<= 1
			}
		}
		mul = [[type]](repeating: [type](repeating: 0, count: size), count: size)
		for a in 0 ..< size {
			for b in 0 ..< size {
				if a == 0 || b == 0 {
					mul[a][b] = type(0)
				} else {
					mul[a][b] = exp[(Int(log[a]) + Int(log[b])) % max]
				}
			}
		}
		inv = [type](repeating: 0, count: size)
		inv[0] = 0
		inv[1] = 1
		for a in 2 ..< size {
			inv[a] = exp[max - Int(log[a])]
		}
	}
	static func destroyTables() {
		mul = []
		inv = []
	}
	static func *(left: Self, right: Self) -> Self {
		return Self(mul[Int(left.value)][Int(right.value)])
	}
	var reciprocal: Self {
		assert(value != 0, "Reciprocal of zero is undefined in Galois Field")
		return Self(Self.inv[Int(value)])
	}
	static func /(left: Self, right: Self) -> Self {
		assert(right.value != 0, "Division by zero is undefined in Galois Field")
		return left * right.reciprocal
	}
	init(_ value: type) {
		self.value = value
	}
}
struct GF16: GaloisField, TableGeneratable {
	typealias type = UInt16
	var value: type
	static var log: [type] = []
	static var exp: [type] = []
	static var count: Int {
		return log.count
	}
	static func generateTables(_ poly: Int) {
		let d = degree(poly)
		assert(d <= 16)
		let size = 1 << d
		let max = size - 1
		log = [type](repeating: 0, count: size)
		exp = [type](repeating: 0, count: size)
		log[0] = type(max)
		exp[max] = 0
		var a = type(1)
		let p = type(truncatingIfNeeded: poly)
		for i in 0 ..< max {
			log[Int(a)] = type(i)
			exp[i] = type(a)
			if a >> (d - 1) == 1 {
				a <<= 1
				a ^= p
			} else {
				a <<= 1
			}
		}
	}
	static func destroyTables() {
		log = []
		exp = []
	}
	static func *(left: Self, right: Self) -> Self {
		if left.value == 0 || right.value == 0 {
			return zero
		}
		let max = count - 1
		return Self(exp[(Int(log[Int(left.value)]) + Int(log[Int(right.value)])) % max])
	}
	var reciprocal: Self {
		assert(value != 0, "Reciprocal of zero is undefined in Galois Field")
		if value == 1 {
			return self
		}
		let max = Self.count - 1
		return Self(Self.exp[max - Int(Self.log[Int(value)])])
	}
	static func /(left: Self, right: Self) -> Self {
		assert(right.value != 0, "Division by zero is undefined in Galois Field")
		if left.value == 0 || right.value == 1 {
			return left
		}
		let max = count - 1
		return Self(exp[(Int(log[Int(left.value)]) - Int(log[Int(right.value)]) + max) % max])
	}
	init(_ value: type) {
		self.value = value
	}
}
protocol PrimitivePolynomial {
	associatedtype type where type: FixedWidthInteger, type: UnsignedInteger
	static var poly: Int { get }
}
struct GaloisFieldReference<P: PrimitivePolynomial>: GaloisField {
	typealias type = P.type
	var value: type
	static var count: Int {
		return 1 << degree(P.poly)
	}
	static func *(left: Self, right: Self) -> Self {
		var a = left.value, b = right.value, t = type(0)
		let p = type(truncatingIfNeeded: P.poly), d = degree(P.poly)
		if a < b {
			swap(&a, &b)
		}
		while a != 0 && b != 0 {
			if b & 1 == 1 {
				t ^= a
			}
			if a >> (d - 1) == 1 {
				a <<= 1
				a ^= p
			} else {
				a <<= 1
			}
			b >>= 1
		}
		return Self(t)
	}
	var reciprocal: Self {
		assert(value != 0, "Reciprocal of zero is undefined in Galois Field")
		if value == 1 {
			return self
		}
		let poly = type(truncatingIfNeeded: P.poly)
		var newr = poly, r = value
		var newt = type(0), t = type(1)
		var k = Self.degree(r)
		let j = Self.degree(P.poly) - k
		newr ^= r << j
		newt ^= t << j
		while newr != 1 {
			let l = Self.degree(newr)
			var j = l - k
			if j < 0 {
				j = -j
				k = l
				swap(&newr, &r)
				swap(&newt, &t)
			}
			newr ^= r << j
			newt ^= t << j
		}
		return Self(newt)
	}
	static func /(left: Self, right: Self) -> Self {
		return left * right.reciprocal
	}
	init(_ value: type) {
		self.value = value
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
struct Testbench<GF: GaloisField & TableGeneratable, PP: PrimitivePolynomial> {
	typealias GFR = GaloisFieldReference<PP>
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
		GF.generateTables(PP.poly)
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
		GF.destroyTables()
	}
}
print("exhaustive test for GF(2^4):")
Testbench<GF8, PrimitivePolynomial19>.run()
print("exhaustive test for GF(2^8):")
Testbench<GF8, PrimitivePolynomial285>.run()
print("exhaustive test for GF(2^14) (takes a minute to complete):")
Testbench<GF16, PrimitivePolynomial16427>.run()
print("exhaustive test for GF(2^16) (be patient, takes minutes to complete):")
Testbench<GF16, PrimitivePolynomial69643>.run()

