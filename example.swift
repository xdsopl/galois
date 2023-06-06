/*
Example use of Galois field arithmetic

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

import Galois

func lagrangeInterpolation<T: GaloisField>(nodes: [(x: T, y: T)], point: T) -> T {
	var sum = T.zero
	for j in 0 ..< nodes.count {
		var num = nodes[j].y, den = T.one
		for m in 0 ..< nodes.count {
			if m != j {
				num *= point - nodes[m].x
				den *= nodes[j].x - nodes[m].x
			}
		}
		sum += num / den
	}
	return sum
}

GF8.generateTables(285)
typealias GF = GF8

// GF16.generateTables(16427)
// typealias GF = GF16

struct PrimitivePolynomial4299161607: PrimitivePolynomial {
	typealias type = UInt32
	static let poly = 4299161607
}
// typealias GF = GaloisFieldReference<PrimitivePolynomial4299161607>

let K = 7, N = 29

// create message with K symbols
var orig_mesg = [(x: GF, y: GF)](repeating: (GF.zero, GF.zero), count: K)
for i in 0 ..< K {
	orig_mesg[i] = (GF(i), GF(Int.random(in: 0 ..< GF.count)))
}
print(orig_mesg.reduce("mesg:") { $0 + " \($1.y.value)" })

// generate N - K redundant symbols from message to form code word
var orig_code = [(x: GF, y: GF)](repeating: (GF.zero, GF.zero), count: N)
for i in 0 ..< N {
	orig_code[i] = (GF(i), lagrangeInterpolation(nodes: orig_mesg, point: GF(i)))
}
print(orig_code.reduce("code:") { $0 + " \($1.y.value)" })

// randomly choose K symbols from code word to simulate erasures
let recv_code = Array(orig_code.shuffled().prefix(K))
print(recv_code.reduce("rpos:") { $0 + " \($1.x.value)" })

// decode message from K received symbols
var recv_mesg = [GF](repeating: GF.zero, count: K)
for i in 0 ..< K {
	recv_mesg[i] = lagrangeInterpolation(nodes: recv_code, point: GF(i))
}
print(recv_mesg.reduce("recv:") { $0 + " \($1.value)" })

// check that the decoded message is indded the original message
for i in 0 ..< K {
	assert(orig_mesg[i].y == recv_mesg[i])
}

// GF8.destroyTables()
// GF16.destroyTables()

