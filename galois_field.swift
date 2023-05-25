/*
Galois field arithmetic

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

protocol PrimitivePolynomial {
	associatedtype type: UnsignedInteger
	static var poly: type { get }
	static var bits: Int { get }
}
struct PrimitivePolynomial29: PrimitivePolynomial {
	typealias type = UInt8
	static let poly: type = 29
	static let bits: Int = 8
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
		var a = left, b = right
		var t = GaloisField<P>(0)
		if a.value < b.value {
			swap(&a, &b)
		}
		while a.value != 0 && b.value != 0 {
			if b.value & 1 == 1 {
				t.value ^= a.value
			}
			if a.value >> (P.bits - 1) == 1 {
				a.value <<= 1
				a.value ^= P.poly
			} else {
				a.value <<= 1
			}
			b.value >>= 1
		}
		return t
	}
	static func *=(left: inout GaloisField<P>, right: GaloisField<P>) {
		left = left * right
	}
	func rcp() -> GaloisField<P> {
		guard value != 0 else {
			fatalError("Reciprocal of zero is undefined in Galois Field")
		}
		var a = self * self, t = a
		for _ in 0 ..< P.bits - 2 {
			a *= a
			t *= a
		}
		return t
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

