/*
UInt8 lookup table Galois field arithmetic

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

public struct GF8: GaloisField, TableGeneratable {
	public typealias type = UInt8
	public var value: type
	public static var mul: [[type]] = []
	public static var inv: [type] = []
	@_transparent
	public static var count: Int {
		return mul.count
	}
	public static func generateTables(_ poly: Int) {
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
	public static func destroyTables() {
		mul = []
		inv = []
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
		return Self(mul[Int(left.value)][Int(right.value)])
	}
	@_transparent
	public var reciprocal: Self {
		assert(value != 0, "Reciprocal of zero is undefined in Galois Field")
		return Self(Self.inv[Int(value)])
	}
	@_transparent
	public static func /(left: Self, right: Self) -> Self {
		assert(right.value != 0, "Division by zero is undefined in Galois Field")
		return left * right.reciprocal
	}
	@_transparent
	public init(_ value: type) {
		assert(value < Self.count, "Value out of range")
		self.value = value
	}
}

