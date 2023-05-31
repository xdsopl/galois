/*
Galois field arithmetic

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

public protocol GaloisField: AdditiveArithmetic {
	associatedtype type where type: FixedWidthInteger, type: UnsignedInteger
	var value: type { get set }
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
	public static func /=(left: inout Self, right: Self) {
		left = left / right
	}
	@_transparent
	public static func degree<T: FixedWidthInteger>(_ poly: T) -> Int {
		return poly.bitWidth - 1 - poly.leadingZeroBitCount
	}
	public var description: String {
		return String(value)
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
		self.value = value
	}
}
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
public protocol PrimitivePolynomial {
	associatedtype type where type: FixedWidthInteger, type: UnsignedInteger
	static var poly: Int { get }
}
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

