/*
Galois field arithmetic

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

import Dispatch

struct GF8: CustomStringConvertible {
	var value: UInt8
	static let poly = 285
	static let log: [UInt8] = logTable()
	static func logTable() -> [UInt8] {
		var tmp = [UInt8](repeating: 0, count: 256)
		tmp[0] = 255
		var a = 1
		for i in 0 ..< 255 {
			tmp[a] = UInt8(i)
			a <<= 1
			if a & 256 != 0 {
				a ^= poly
			}
		}
		return tmp
	}
	static let exp: [UInt8] = expTable()
	static func expTable() -> [UInt8] {
		var tmp = [UInt8](repeating: 0, count: 256)
		tmp[255] = 0
		var a = 1
		for i in 0 ..< 255 {
			tmp[i] = UInt8(a)
			a <<= 1
			if a & 256 != 0 {
				a ^= poly
			}
		}
		return tmp
	}
	static func +(left: GF8, right: GF8) -> GF8 {
		return GF8(left.value ^ right.value)
	}
	static func +=(left: inout GF8, right: GF8) {
		left = left + right
	}
	static func *(left: GF8, right: GF8) -> GF8 {
		if left.value == 0 || right.value == 0 {
			return GF8(0)
		}
		return GF8(exp[(Int(log[Int(left.value)]) + Int(log[Int(right.value)])) % 255])
	}
	static func *=(left: inout GF8, right: GF8) {
		left = left * right
	}
	func rcp() -> GF8 {
		assert(value != 0, "Reciprocal of zero is undefined in Galois Field")
		if value == 1 {
			return self
		}
		return GF8(GF8.exp[(255 - Int(GF8.log[Int(value)])) % 255])
	}
	static func /(left: GF8, right: GF8) -> GF8 {
		assert(right.value != 0, "Division by zero is undefined in Galois Field")
		if left.value == 0 || right.value == 1 {
			return left
		}
		return GF8(GF8.exp[(Int(GF8.log[Int(left.value)]) - Int(GF8.log[Int(right.value)]) + 255) % 255])
	}
	static func /=(left: inout GF8, right: GF8) {
		left = left / right
	}
	init(_ value: UInt8) {
		self.value = value
	}
	var description: String {
		return String(value)
	}
}
struct GF16: CustomStringConvertible {
	var value: UInt16
	static let poly = 69643
	static let log: [UInt16] = logTable()
	static func logTable() -> [UInt16] {
		var tmp = [UInt16](repeating: 0, count: 65536)
		tmp[0] = 65535
		var a = 1
		for i in 0 ..< 65535 {
			tmp[a] = UInt16(i)
			a <<= 1
			if a & 65536 != 0 {
				a ^= poly
			}
		}
		return tmp
	}
	static let exp: [UInt16] = expTable()
	static func expTable() -> [UInt16] {
		var tmp = [UInt16](repeating: 0, count: 65536)
		tmp[65535] = 0
		var a = 1
		for i in 0 ..< 65535 {
			tmp[i] = UInt16(a)
			a <<= 1
			if a & 65536 != 0 {
				a ^= poly
			}
		}
		return tmp
	}
	static func +(left: GF16, right: GF16) -> GF16 {
		return GF16(left.value ^ right.value)
	}
	static func +=(left: inout GF16, right: GF16) {
		left = left + right
	}
	static func *(left: GF16, right: GF16) -> GF16 {
		if left.value == 0 || right.value == 0 {
			return GF16(0)
		}
		return GF16(exp[(Int(log[Int(left.value)]) + Int(log[Int(right.value)])) % 65535])
	}
	static func *=(left: inout GF16, right: GF16) {
		left = left * right
	}
	func rcp() -> GF16 {
		assert(value != 0, "Reciprocal of zero is undefined in Galois Field")
		if value == 1 {
			return self
		}
		return GF16(GF16.exp[(65535 - Int(GF16.log[Int(value)])) % 65535])
	}
	static func /(left: GF16, right: GF16) -> GF16 {
		assert(right.value != 0, "Division by zero is undefined in Galois Field")
		if left.value == 0 || right.value == 1 {
			return left
		}
		return GF16(GF16.exp[(Int(GF16.log[Int(left.value)]) - Int(GF16.log[Int(right.value)]) + 65535) % 65535])
	}
	static func /=(left: inout GF16, right: GF16) {
		left = left / right
	}
	init(_ value: UInt16) {
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
typealias GF = GaloisField<PP>
//typealias GF = GF8
//typealias GF = GF16
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
var dummy = PP.zero
let mulBegin = DispatchTime.now().uptimeNanoseconds
for i in 0 ... PP.max {
	for j in 0 ... PP.max {
		dummy ^= (GF(i) * GF(j)).value
	}
}
let mulEnd = DispatchTime.now().uptimeNanoseconds
printElapsedTime("mul", mulBegin, mulEnd)
let rcpBegin = DispatchTime.now().uptimeNanoseconds
for j in 1 ... PP.max {
	dummy ^= GF(j).rcp().value
}
let rcpEnd = DispatchTime.now().uptimeNanoseconds
printElapsedTime("rcp", rcpBegin, rcpEnd)
print("dummy: \(dummy)")

