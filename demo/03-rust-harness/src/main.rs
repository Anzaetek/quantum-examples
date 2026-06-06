//! Minimal Rust harness for the Quantum Toolkit — talks to the shipped
//! `quantum-server` over the AF_UNIX JSON-RPC socket. Depends on nothing from
//! the toolkit source: this is how a customer integrates the binary-only
//! distribution into their own Rust application.
//!
//! Wire protocol (see the dist's `docs/SERVER.md`): every message is a 4-byte
//! big-endian length prefix followed by a UTF-8 JSON body. Request shape:
//!   { "method": "...", "params": { ... }, "id": N }
//!
//! Run:
//!   # 1. start the server from the dist (in another shell):
//!   $QUANTUM_DIST/bin/quantum-server --listen unix:/tmp/quantum-demo.sock
//!   # 2. point the harness at it and run:
//!   QUANTUM_SOCKET=/tmp/quantum-demo.sock cargo run

use std::io::{Read, Write};
use std::os::unix::net::UnixStream;
use std::process::exit;

use serde_json::{json, Value};

/// One request/response cycle over a fresh connection.
fn rpc(sock_path: &str, method: &str, params: Value) -> std::io::Result<Value> {
    let mut stream = UnixStream::connect(sock_path)?;
    let body = json!({ "method": method, "params": params, "id": 1 }).to_string();
    let bytes = body.as_bytes();
    stream.write_all(&(bytes.len() as u32).to_be_bytes())?; // 4-byte BE length
    stream.write_all(bytes)?;
    stream.flush()?;

    let mut len_buf = [0u8; 4];
    stream.read_exact(&mut len_buf)?;
    let n = u32::from_be_bytes(len_buf) as usize;
    let mut resp = vec![0u8; n];
    stream.read_exact(&mut resp)?;
    Ok(serde_json::from_slice(&resp).expect("server returned valid JSON"))
}

fn main() {
    let sock = std::env::var("QUANTUM_SOCKET").unwrap_or_else(|_| "/tmp/quantum-demo.sock".into());
    let qasm = include_str!("../circuit.qasm");
    println!("harness → quantum-server at unix:{sock}");
    println!("circuit: 3 qubits, two adjacent Hadamards (should optimize away)\n");

    let mut fails = 0;
    let check = |cond: bool, label: &str, fails: &mut i32| {
        if cond {
            println!("  ✓ {label}");
        } else {
            println!("  ✗ {label}");
            *fails += 1;
        }
    };

    // ping
    match rpc(&sock, "ping", json!({})) {
        Ok(v) => check(
            v["result"].to_string().contains("pong") || v.get("result").is_some(),
            "server responds to ping",
            &mut fails,
        ),
        Err(e) => {
            eprintln!("cannot reach server at {sock}: {e}\nstart it with: \
                $QUANTUM_DIST/bin/quantum-server --listen unix:{sock}");
            exit(2);
        }
    }

    // info — circuit statistics
    let info = rpc(&sock, "info", json!({ "source": qasm, "format": "qasm" }))
        .expect("info rpc")["result"]
        .clone();
    println!("\ninfo → {info}");
    let qubits = info["num_qubits"].as_u64().unwrap_or(0);
    let gates = info["gate_count"].as_u64().unwrap_or(0);
    check(qubits == 3, "circuit has 3 qubits", &mut fails);
    check(gates == 4, "circuit has 4 gates before optimization", &mut fails);

    // optimize — adjacent Hadamards must cancel
    let opt = rpc(
        &sock,
        "optimize",
        json!({ "source": qasm, "format": "qasm", "iterations": 3 }),
    )
    .expect("optimize rpc")["result"]
        .clone();
    let before = opt["gate_count_before"].as_u64().unwrap_or(0);
    let after = opt["gate_count_after"].as_u64().unwrap_or(0);
    println!("\noptimize → gate_count {before} → {after}");
    check(
        after < before,
        "optimizer removed the redundant Hadamard pair (gates shrank)",
        &mut fails,
    );
    check(after == 2, "optimized to 2 gates (CX, CX)", &mut fails);

    println!();
    if fails == 0 {
        println!("OK — harness verified the shipped server numerically");
    } else {
        eprintln!("FAIL — {fails} check(s) failed");
        exit(1);
    }
}
