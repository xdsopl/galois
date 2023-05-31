/*
Reference Galois field arithmetic

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

public struct GaloisFieldReference<P: PrimitivePolynomial>: GaloisField {
	public typealias type = P.type
	public var value: type
	@_transparent
	public static var count: Int {
		return 1 << degree(P.poly)
	}
	@_transparent
	public static func *(left: Self, right: Self) -> Self {
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
	@_transparent
	public var reciprocal: Self {
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
	@_transparent
	public static func /(left: Self, right: Self) -> Self {
		return left * right.reciprocal
	}
	@_transparent
	public init(_ value: type) {
		self.value = value
	}
}

