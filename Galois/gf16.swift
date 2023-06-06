/*
UInt16 lookup table Galois field arithmetic

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

public struct GF16: GaloisField, TableGeneratable {
	public typealias type = UInt16
	public var value: type
	public static var log: [type] = []
	public static var exp: [type] = []
	@_transparent
	public static var count: Int {
		return log.count
	}
	public static func generateTables(_ poly: Int) {
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
	public static func destroyTables() {
		log = []
		exp = []
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
	public static func *(left: Self, right: Self) -> Self {
		if left.value == 0 || right.value == 0 {
			return zero
		}
		let max = count - 1
		return Self(exp[(Int(log[Int(left.value)]) + Int(log[Int(right.value)])) % max])
	}
	@_transparent
	public var reciprocal: Self {
		assert(value != 0, "Reciprocal of zero is undefined in Galois Field")
		if value == 1 {
			return self
		}
		let max = Self.count - 1
		return Self(Self.exp[max - Int(Self.log[Int(value)])])
	}
	@_transparent
	public static func /(left: Self, right: Self) -> Self {
		assert(right.value != 0, "Division by zero is undefined in Galois Field")
		if left.value == 0 || right.value == 1 {
			return left
		}
		let max = count - 1
		return Self(exp[(Int(log[Int(left.value)]) - Int(log[Int(right.value)]) + max) % max])
	}
	@_transparent
	public init(_ value: type) {
		self.value = value
	}
}

