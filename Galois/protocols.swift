/*
Protocols for Galois field arithmetic

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

public protocol GaloisField: AdditiveArithmetic {
	associatedtype type where type: FixedWidthInteger, type: UnsignedInteger
	var value: type { get set }
	static var one: Self { get }
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
	@_transparent
	public static var zero: Self {
		return Self(0)
	}
	@_transparent
	public static var one: Self {
		return Self(1)
	}
	@_transparent
	public static func +(left: Self, right: Self) -> Self {
		return Self(left.value ^ right.value)
	}
	@_transparent
	public static func -(left: Self, right: Self) -> Self {
		return left + right
	}
	@_transparent
	public static func *=(left: inout Self, right: Self) {
		left = left * right
	}
	@_transparent
	public static func /(left: Self, right: Self) -> Self {
		assert(right.value != 0, "Division by zero is undefined in Galois Field")
		return left * right.reciprocal
	}
	@_transparent
	public static func /=(left: inout Self, right: Self) {
		left = left / right
	}
	@_transparent
	public static func degree<T: FixedWidthInteger>(_ poly: T) -> Int {
		return poly.bitWidth - 1 - poly.leadingZeroBitCount
	}
	@_transparent
	public init(_ value: Int) {
		self.init(type(value))
	}
}

public protocol TableGeneratable {
	static func generateTables(_ poly: Int)
	static func destroyTables()
}

public protocol PrimitivePolynomial {
	associatedtype type where type: FixedWidthInteger, type: UnsignedInteger
	static var poly: Int { get }
}

public protocol PrimeNumber {
	associatedtype type where type: FixedWidthInteger, type: UnsignedInteger
	static var number: Int { get }
}

