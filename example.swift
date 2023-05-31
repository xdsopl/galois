/*
Example use of Galois field arithmetic

Copyright 2023 Ahmet Inan <xdsopl@gmail.com>
*/

import Galois

func lagrangeInterpolation<T: GaloisField>(x: [T], y: [T], p: T) -> T {
	var sum = T.zero
	for j in 0 ..< y.count {
		var num = y[j], den = T.one
		for m in 0 ..< x.count {
			if m != j {
				num *= p - x[m]
				den *= x[j] - x[m]
			}
		}
		sum += num / den
	}
	return sum
}

GF8.generateTables(285)
typealias GF = GF8

let K = 7, N = 29

// create message with K symbols
var orig_mesg = [GF](repeating: GF.zero, count: K)
for i in 0 ..< K {
	orig_mesg[i] = GF(Int.random(in: 0 ..< GF.count))
}
print(orig_mesg.reduce("mesg:") { $0 + " \($1.value)" })

// original positions of each message symbol
var orig_pos = [GF](repeating: GF.zero, count: N)
for i in 0 ..< N {
	orig_pos[i] = GF(i)
}

// generate N - K redundant symbols from message to form code word
var orig_code = [GF](repeating: GF.zero, count: N)
for i in 0 ..< N {
	orig_code[i] = lagrangeInterpolation(x: Array(orig_pos.prefix(K)), y: orig_mesg, p: GF(i))
}
print(orig_code.reduce("code:") { $0 + " \($1.value)" })

// randomly choose K positions from code word to simulate erasures
let recv_pos = Array(orig_pos.shuffled().prefix(K))
print(recv_pos.reduce("rpos:") { $0 + " \($1.value)" })

// create received array from above K random positions of code word
var recv_code = [GF](repeating: GF.zero, count: K)
for i in 0 ..< K {
	recv_code[i] = orig_code[Int(recv_pos[i].value)]
}

// decode message from K received symbols
var recv_mesg = [GF](repeating: GF.zero, count: K)
for i in 0 ..< K {
	recv_mesg[i] = lagrangeInterpolation(x: recv_pos, y: recv_code, p: GF(i))
}
print(recv_mesg.reduce("recv:") { $0 + " \($1.value)" })


GF.destroyTables()

