/*
Cauchy matrix based erasure coding example

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

import Galois

func cauchyMatrix<T: GaloisField>(_ i: Int, _ j: Int) -> T {
	let row = T(i), col = T(j)
	return (row + col).reciprocal
}
func cauchyInverse<T: GaloisField>(_ rows: [T], _ i: Int, _ j: Int, _ n: Int) -> T {
	let col_i = T(i)
	var prod_xy = T.one, prod_x = T.one, prod_y = T.one
	for k in 0 ..< n {
		let col_k = T(k)
		prod_xy *= (rows[j] + col_k) * (rows[k] + col_i)
		if k != j {
			prod_x *= rows[j] - rows[k]
		}
		if k != i {
			prod_y *= col_i - col_k
		}
	}
	return prod_xy / ((rows[j] + col_i) * prod_x * prod_y)
}

// GF8.generateTables(285)
// typealias GF = GF8

// GF16.generateTables(16427)
// typealias GF = GF16

struct PrimitivePolynomial4299161607: PrimitivePolynomial {
	typealias type = UInt32
	static let poly = 4299161607
}
// typealias GF = GaloisFieldReference<PrimitivePolynomial4299161607>

struct PrimeNumber65537: PrimeNumber {
	typealias type = UInt32
	static let number = 65537
}
struct PrimeNumber257: PrimeNumber {
	typealias type = UInt16
	static let number = 257
}
// typealias GF = PrimeField<PrimeNumber65537>
typealias GF = PrimeField<PrimeNumber257>

let K = 7, N = 29

// create message with K symbols
var orig_mesg = [GF](repeating: GF.zero, count: K)
for i in 0 ..< K {
	orig_mesg[i] = GF(Int.random(in: 0 ..< GF.count))
}
print(orig_mesg.reduce("mesg:") { $0 + " \($1.value)" })

// randomly choose K rows to simulate erasures
var orig_rows = [GF](repeating: GF.zero, count: N)
for i in 0 ..< N {
	orig_rows[i] = GF(K + i)
}
let recv_rows = Array(orig_rows.shuffled().prefix(K))
print(recv_rows.reduce("rpos:") { $0 + " \(Int($1.value) - K)" })

// generate only K symbols from message to form received code word
var recv_code = [GF](repeating: GF.zero, count: K)
for i in 0 ..< K {
	for j in 0 ..< K {
		recv_code[i] += orig_mesg[j] * cauchyMatrix(Int(recv_rows[i].value), j)
	}
}
print(recv_code.reduce("code:") { $0 + " \($1.value)" })

// decode message from K received symbols
var recv_mesg = [GF](repeating: GF.zero, count: K)
for i in 0 ..< K {
	for j in 0 ..< K {
		recv_mesg[i] += recv_code[j] * cauchyInverse(recv_rows, i, j, K)
	}
}
print(recv_mesg.reduce("recv:") { $0 + " \($1.value)" })

// check that the decoded message is indded the original message
for i in 0 ..< K {
	assert(orig_mesg[i] == recv_mesg[i])
}

// GF8.destroyTables()
// GF16.destroyTables()

