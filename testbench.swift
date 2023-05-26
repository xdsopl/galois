/*
Galois field arithmetic

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

import Dispatch

struct GF8: CustomStringConvertible {
	typealias type = UInt8
	var value: type
	static let poly = 285
	static let size = 256
	static let max = size - 1
	static let (mul, inv): ([type], [type]) = genMulInvTables()
	static func genMulInvTables() -> ([type], [type]) {
		var log = [type](repeating: 0, count: size)
		var exp = [type](repeating: 0, count: size)
		log[0] = type(max)
		exp[max] = 0
		var a = 1
		for i in 0 ..< max {
			log[a] = type(i)
			exp[i] = type(a)
			a <<= 1
			if a & size != 0 {
				a ^= poly
			}
		}
		var mul = [type](repeating: 0, count: size * size)
		for a in 0 ..< size {
			for b in 0 ..< size {
				if a == 0 || b == 0 {
					mul[size * a + b] = type(0)
				} else {
					mul[size * a + b] = exp[(Int(log[a]) + Int(log[b])) % max]
				}
			}
		}
		var inv = [type](repeating: 0, count: size)
		inv[0] = 0
		inv[1] = 1
		for a in 2 ..< size {
			inv[a] = exp[max - Int(log[a])]
		}
		return (mul, inv)
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
	var description: String {
		return String(value)
	}
}
struct GF16: CustomStringConvertible {
	typealias type = UInt16
	var value: type
	static let poly = 69643
	static let size = 65536
	static let max = size - 1
	static let (log, exp): ([type], [type]) = genLogExpTables()
	static func genLogExpTables() -> ([type], [type]) {
		var log = [type](repeating: 0, count: size)
		var exp = [type](repeating: 0, count: size)
		log[0] = type(max)
		exp[max] = 0
		var a = 1
		for i in 0 ..< max {
			log[a] = type(i)
			exp[i] = type(a)
			a <<= 1
			if a & size != 0 {
				a ^= poly
			}
		}
		return (log, exp)
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
	var description: String {
		return String(value)
	}
}
protocol PrimitivePolynomial {
	associatedtype type where type: FixedWidthInteger, type: UnsignedInteger
	static var bits: Int { get }
	static var poly: type { get }
	static var zero: type { get }
	static var one: type { get }
	static var max: type { get }
}
struct GaloisField<P: PrimitivePolynomial>: CustomStringConvertible {
	var value: P.type
	static func +(left: GaloisField<P>, right: GaloisField<P>) -> GaloisField<P> {
		return GaloisField<P>(left.value ^ right.value)
	}
	static func +=(left: inout GaloisField<P>, right: GaloisField<P>) {
		left = left + right
	}
	static func *(left: GaloisField<P>, right: GaloisField<P>) -> GaloisField<P> {
		var a = left.value, b = right.value, t = P.zero
		if a < b {
			swap(&a, &b)
		}
		while a != 0 && b != 0 {
			if b & 1 == 1 {
				t ^= a
			}
			if a >> (P.bits - 1) == 1 {
				a <<= 1
				a ^= P.poly
			} else {
				a <<= 1
			}
			b >>= 1
		}
		return GaloisField<P>(t)
	}
	static func *=(left: inout GaloisField<P>, right: GaloisField<P>) {
		left = left * right
	}
	func rcp() -> GaloisField<P> {
		assert(value != 0, "Reciprocal of zero is undefined in Galois Field")
		if value == 1 {
			return self
		}
		var newr = P.poly, r = value
		var newt = P.zero, t = P.one
		let degree: (P.type) -> Int = {
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
		return GaloisField<P>(newt)
	}
	static func /(left: GaloisField<P>, right: GaloisField<P>) -> GaloisField<P> {
		return left * right.rcp()
	}
	static func /=(left: inout GaloisField<P>, right: GaloisField<P>) {
		left = left / right
	}
	init(_ value: P.type) {
		self.value = value
	}
	var description: String {
		return String(value)
	}
}
struct PrimitivePolynomial285: PrimitivePolynomial {
	typealias type = UInt8
	static let bits = 8
	static let poly = type(Int(285) & Int(type.max))
	static let zero = type(0)
	static let one = type(1)
	static let max = type.max
}
struct PrimitivePolynomial69643: PrimitivePolynomial {
	typealias type = UInt16
	static let bits = 16
	static let poly = type(Int(69643) & Int(type.max))
	static let zero = type(0)
	static let one = type(1)
	static let max = type.max
}
struct PrimitivePolynomial4299161607: PrimitivePolynomial {
	typealias type = UInt32
	static let bits = 32
	static let poly = type(Int(4299161607) & Int(type.max))
	static let zero = type(0)
	static let one = type(1)
	static let max = type.max
}
typealias PP = PrimitivePolynomial69643
//typealias PP = PrimitivePolynomial285
typealias GFR = GaloisField<PP>
typealias GF = GF16
//typealias GF = GF8
let a = GF(2)
let b = GF(3)
print("\(a) + \(b) = \(a + b)")
print("\(a) * \(b) = \(a * b)")
print("\(a) / \(b) = \(a / b)")
print("rcp(\(a)) = \(a.rcp())")
let size = MemoryLayout.size(ofValue: a)
print("size of GF: \(size) byte\(size == 1 ? "" : "s")")
func printElapsedTime(_ name: String, _ begin: UInt64, _ end: UInt64)
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
let mulBegin = DispatchTime.now().uptimeNanoseconds
for i in 0 ... PP.max {
	for j in 0 ... PP.max {
		assert((GF(i) * GF(j)).value == (GFR(i) * GFR(j)).value)
	}
}
let mulEnd = DispatchTime.now().uptimeNanoseconds
printElapsedTime("mul", mulBegin, mulEnd)
let divBegin = DispatchTime.now().uptimeNanoseconds
for i in 0 ... PP.max {
	for j in 1 ... PP.max {
		assert((GF(i) / GF(j)).value == (GFR(i) / GFR(j)).value)
	}
}
let divEnd = DispatchTime.now().uptimeNanoseconds
printElapsedTime("div", divBegin, divEnd)
let rcpBegin = DispatchTime.now().uptimeNanoseconds
for j in 1 ... PP.max {
	assert(GF(j).rcp().value == GFR(j).rcp().value)
}
let rcpEnd = DispatchTime.now().uptimeNanoseconds
printElapsedTime("rcp", rcpBegin, rcpEnd)

