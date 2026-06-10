// Rotated surface code [[9,1,3]] — bit-flip sector (Z-check syndrome extraction).
// 9 data qubits (0..8) on a 3x3 grid + 4 Z-type stabilizer ancillas (9..12).
// One X error is injected on the centre data qubit (4); the Z-checks containing
// qubit 4 fire, giving syndrome 1,1,0,0.
OPENQASM 2.0;
include "qelib1.inc";
qreg q[13];
creg s[4];

// injected bit-flip error
x q[4];

// Z-check 0: data {0,1,3,4} -> ancilla 9
cx q[0], q[9];
cx q[1], q[9];
cx q[3], q[9];
cx q[4], q[9];
measure q[9] -> s[0];

// Z-check 1: data {4,5,7,8} -> ancilla 10
cx q[4], q[10];
cx q[5], q[10];
cx q[7], q[10];
cx q[8], q[10];
measure q[10] -> s[1];

// Z-check 2: data {1,2} -> ancilla 11 (boundary, weight 2)
cx q[1], q[11];
cx q[2], q[11];
measure q[11] -> s[2];

// Z-check 3: data {6,7} -> ancilla 12 (boundary, weight 2)
cx q[6], q[12];
cx q[7], q[12];
measure q[12] -> s[3];
