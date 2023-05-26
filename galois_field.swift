/*
Galois field arithmetic

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

protocol PrimitivePolynomial {
	associatedtype type where type: FixedWidthInteger, type: UnsignedInteger
	static var poly: type { get }
	static var bits: Int { get }
	static var zero: type { get }
	static var one: type { get }
}
struct PrimitivePolynomial29: PrimitivePolynomial {
	typealias type = UInt8
	static let poly: type = 29
	static let bits: Int = 8
	static let zero: type = 0
	static let one: type = 1
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
		guard value != 0 else {
			fatalError("Reciprocal of zero is undefined in Galois Field")
		}
#if true
		if value == 1 {
			return self
		}
		var newr = P.poly, r = value
		var newt = P.zero, t = P.one
		let degree: (P.type) -> Int = {
#if true
			return $0.bitWidth - 1 - $0.leadingZeroBitCount
#else
			var d = 0, a = $0 >> 1
			while a != 0 {
				d += 1
				a >>= 1
			}
			return d
#endif
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
#else
		var a = self * self, t = a
		for _ in 0 ..< P.bits - 2 {
			a *= a
			t *= a
		}
		return t
#endif
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
typealias GF = GaloisField<PrimitivePolynomial29>
let a = GF(2)
let b = GF(3)
print("\(a) + \(b) = \(a + b)")
print("\(a) * \(b) = \(a * b)")
print("\(a) / \(b) = \(a / b)")
print("rcp(\(a)) = \(a.rcp())")
print(MemoryLayout.size(ofValue: a))

