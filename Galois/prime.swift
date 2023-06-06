/*
Prime Galois field arithmetic

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

public struct PrimeField<P: PrimeNumber>: GaloisField {
	public typealias type = P.type
	public var value: type
	@_transparent
	public static var count: Int {
		return P.number
	}
	@_transparent
	public static func +(left: Self, right: Self) -> Self {
		return Self((Int(left.value) + Int(right.value)) % P.number)
	}
	@_transparent
	public static func -(left: Self, right: Self) -> Self {
		return Self((Int(left.value) - Int(right.value) + P.number) % P.number)
	}
	@_transparent
	public static func *(left: Self, right: Self) -> Self {
		return Self((Int(left.value) * Int(right.value)) % P.number)
	}
	@_transparent
	public var reciprocal: Self {
		assert(value != 0, "Reciprocal of zero is undefined in Galois Field")
		if value == 1 {
			return self
		}
		var (t, newt) = (0, 1)
		var (r, newr) = (P.number, Int(value))
		while newr != 0 {
			let quotient = r / newr
			(t, newt) = (newt, t - quotient * newt)
			(r, newr) = (newr, r - quotient * newr)
		}
		assert(r <= 1, "\(value) is not invertible")
		if t < 0 {
			t += P.number
		}
		return Self(t)
	}
	@_transparent
	public init(_ value: type) {
		self.value = value
	}
}

