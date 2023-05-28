/*
Galois field arithmetic

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

import Dispatch

protocol GaloisFieldProtocol: Equatable {
	associatedtype type where type: FixedWidthInteger, type: UnsignedInteger
	var value: type { get set }
	static func +(left: Self, right: Self) -> Self
	static func +=(left: inout Self, right: Self)
	static func *(left: Self, right: Self) -> Self
	static func *=(left: inout Self, right: Self)
	static func /(left: Self, right: Self) -> Self
	static func /=(left: inout Self, right: Self)
	func rcp() -> Self
	init(_ value: type)
	init(_ value: Int)
}
protocol TableGeneratable {
	static func generateTables(_ poly: Int)
	static func destroyTables()
}
struct GF8: GaloisFieldProtocol, TableGeneratable {
	typealias type = UInt8
	var value: type
	static var size = 0
	static var mul: [type] = []
	static var inv: [type] = []
	static func generateTables(_ poly: Int) {
		var deg = -1
		var tmp = poly
		while tmp != 0 {
			tmp >>= 1
			deg += 1
		}
		size = 1 << deg
		let max = size - 1
		var log = [type](repeating: 0, count: size)
		var exp = [type](repeating: 0, count: size)
		log[0] = type(max)
		exp[max] = 0
		var a = type(1)
		let p = type(poly & Int(type.max))
		for i in 0 ..< max {
			log[Int(a)] = type(i)
			exp[i] = type(a)
			if a >> (deg - 1) == 1 {
				a <<= 1
				a ^= p
			} else {
				a <<= 1
			}
		}
		mul = [type](repeating: 0, count: size * size)
		for a in 0 ..< size {
			for b in 0 ..< size {
				if a == 0 || b == 0 {
					mul[size * a + b] = type(0)
				} else {
					mul[size * a + b] = exp[(Int(log[a]) + Int(log[b])) % max]
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
	static func +(left: Self, right: Self) -> Self {
		return Self(left.value ^ right.value)
	}
	static func +=(left: inout Self, right: Self) {
		left = left + right
	}
	static func *(left: Self, right: Self) -> Self {
		return Self(mul[size * Int(left.value) + Int(right.value)])
	}
	static func *=(left: inout Self, right: Self) {
		left = left * right
	}
	func rcp() -> Self {
		assert(value != 0, "Reciprocal of zero is undefined in Galois Field")
		return Self(Self.inv[Int(value)])
	}
	static func /(left: Self, right: Self) -> Self {
		assert(right.value != 0, "Division by zero is undefined in Galois Field")
		return left * right.rcp()
	}
	static func /=(left: inout Self, right: Self) {
		left = left / right
	}
	init(_ value: type) {
		self.value = value
	}
	init(_ value: Int) {
		self.init(type(value))
	}
}
struct GF16: GaloisFieldProtocol, TableGeneratable {
	typealias type = UInt16
	var value: type
	static let bits = 16
	static let size = 1 << bits
	static let max = size - 1
	static var log: [type] = []
	static var exp: [type] = []
	static func generateTables(_ poly: Int) {
		log = [type](repeating: 0, count: size)
		exp = [type](repeating: 0, count: size)
		log[0] = type(max)
		exp[max] = 0
		var a = type(1)
		let p = type(poly & Int(type.max))
		for i in 0 ..< max {
			log[Int(a)] = type(i)
			exp[i] = type(a)
			if a >> (bits - 1) == 1 {
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
	static func +(left: Self, right: Self) -> Self {
		return Self(left.value ^ right.value)
	}
	static func +=(left: inout Self, right: Self) {
		left = left + right
	}
	static func *(left: Self, right: Self) -> Self {
		if left.value == 0 || right.value == 0 {
			return Self(0)
		}
		return Self(exp[(Int(log[Int(left.value)]) + Int(log[Int(right.value)])) % max])
	}
	static func *=(left: inout Self, right: Self) {
		left = left * right
	}
	func rcp() -> Self {
		assert(value != 0, "Reciprocal of zero is undefined in Galois Field")
		if value == 1 {
			return self
		}
		return Self(Self.exp[Self.max - Int(Self.log[Int(value)])])
	}
	static func /(left: Self, right: Self) -> Self {
		assert(right.value != 0, "Division by zero is undefined in Galois Field")
		if left.value == 0 || right.value == 1 {
			return left
		}
		return Self(Self.exp[(Int(Self.log[Int(left.value)]) - Int(Self.log[Int(right.value)]) + max) % max])
	}
	static func /=(left: inout Self, right: Self) {
		left = left / right
	}
	init(_ value: type) {
		self.value = value
	}
	init(_ value: Int) {
		self.init(type(value))
	}
}
protocol PrimitivePolynomial {
	associatedtype type where type: FixedWidthInteger, type: UnsignedInteger
	static var bits: Int { get }
	static var poly: Int { get }
	static var zero: type { get }
	static var one: type { get }
	static var max: type { get }
}
struct GaloisField<P: PrimitivePolynomial>: GaloisFieldProtocol {
	typealias type = P.type
	var value: type
	static func +(left: Self, right: Self) -> Self {
		return Self(left.value ^ right.value)
	}
	static func +=(left: inout Self, right: Self) {
		left = left + right
	}
	static func *(left: Self, right: Self) -> Self {
		var a = left.value, b = right.value, t = P.zero
		let p = type(P.poly & Int(type.max))
		if a < b {
			swap(&a, &b)
		}
		while a != 0 && b != 0 {
			if b & 1 == 1 {
				t ^= a
			}
			if a >> (P.bits - 1) == 1 {
				a <<= 1
				a ^= p
			} else {
				a <<= 1
			}
			b >>= 1
		}
		return Self(t)
	}
	static func *=(left: inout Self, right: Self) {
		left = left * right
	}
	func rcp() -> Self {
		assert(value != 0, "Reciprocal of zero is undefined in Galois Field")
		if value == 1 {
			return self
		}
		let poly = type(P.poly & Int(type.max))
		var newr = poly, r = value
		var newt = P.zero, t = P.one
		let degree: (type) -> Int = {
			return $0.bitWidth - 1 - $0.leadingZeroBitCount
		}
		var k = degree(r)
		let j = P.bits - k
		newr ^= r << j
		newt ^= t << j
		while newr != 1 {
			let l = degree(newr)
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
		return left * right.rcp()
	}
	static func /=(left: inout Self, right: Self) {
		left = left / right
	}
	init(_ value: type) {
		self.value = value
	}
	init(_ value: Int) {
		self.init(type(value))
	}
}
extension GF8: CustomStringConvertible {
	var description: String {
		return String(value)
	}
}
extension GF16: CustomStringConvertible {
	var description: String {
		return String(value)
	}
}
extension GaloisField: CustomStringConvertible {
	var description: String {
		return String(value)
	}
}
struct PrimitivePolynomial19: PrimitivePolynomial {
	typealias type = UInt8
	static let bits = 4
	static let poly = 19
	static let zero = type(0)
	static let one = type(1)
	static let max = type(15)
}
struct PrimitivePolynomial285: PrimitivePolynomial {
	typealias type = UInt8
	static let bits = 8
	static let poly = 285
	static let zero = type(0)
	static let one = type(1)
	static let max = type.max
}
struct PrimitivePolynomial69643: PrimitivePolynomial {
	typealias type = UInt16
	static let bits = 16
	static let poly = 69643
	static let zero = type(0)
	static let one = type(1)
	static let max = type.max
}
struct PrimitivePolynomial4299161607: PrimitivePolynomial {
	typealias type = UInt32
	static let bits = 32
	static let poly = 4299161607
	static let zero = type(0)
	static let one = type(1)
	static let max = type.max
}
struct Testbench<GF: GaloisFieldProtocol & TableGeneratable, PP: PrimitivePolynomial> {
	typealias GFR = GaloisField<PP>
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
		GF.generateTables(Int(PP.poly))
		let mulBegin = DispatchTime.now().uptimeNanoseconds
		for i in 0 ... Int(PP.max) {
			for j in 0 ... Int(PP.max) {
				assert((GF(i) * GF(j)).value == (GFR(i) * GFR(j)).value)
			}
		}
		let mulEnd = DispatchTime.now().uptimeNanoseconds
		printElapsedTime("mul", mulBegin, mulEnd)
		let divBegin = DispatchTime.now().uptimeNanoseconds
		for i in 0 ... Int(PP.max) {
			for j in 1 ... Int(PP.max) {
				assert((GF(i) / GF(j)).value == (GFR(i) / GFR(j)).value)
			}
		}
		let divEnd = DispatchTime.now().uptimeNanoseconds
		printElapsedTime("div", divBegin, divEnd)
		let rcpBegin = DispatchTime.now().uptimeNanoseconds
		for j in 1 ... Int(PP.max) {
			assert(GF(j).rcp().value == GFR(j).rcp().value)
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
print("exhaustive test for GF(2^16) (be patient, takes minutes to complete):")
Testbench<GF16, PrimitivePolynomial69643>.run()

