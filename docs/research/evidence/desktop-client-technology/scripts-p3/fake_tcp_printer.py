#!/usr/bin/env python3
"""Tier-E probe: a fake ESC/POS network printer for hardware-less tests.
Listens on 127.0.0.1:<port>, records every byte, answers real-time status DLE EOT n (10 04 n)
with a fixed one-byte reply taken from a state table, and can drop the connection after N bytes
(fault injection). The reply bytes are TEST VALUES, not a vendor's bit layout (F204: layouts are per model).
Usage: fake_tcp_printer.py BINFILE   (self-test: starts server thread, sends BINFILE + status queries, prints result)"""
import socket, sys, threading
STATE = {1: 0x12, 2: 0x12, 3: 0x12, 4: 0x12}   # test values only
def serve(srv, log, drop_after=None):
    c, _ = srv.accept(); got = bytearray()
    while True:
        b = c.recv(4096)
        if not b: break
        got += b
        i = 0
        while True:
            j = got.find(b"\x10\x04", i)
            if j < 0 or j + 2 >= len(got): break
            c.sendall(bytes([STATE.get(got[j+2], 0)])); i = j + 3
        if drop_after and len(got) >= drop_after: c.close(); break
    log.append(bytes(got))
if __name__ == "__main__":
    data = open(sys.argv[1], "rb").read()
    srv = socket.socket(); srv.bind(("127.0.0.1", 0)); srv.listen(1); port = srv.getsockname()[1]
    log = []; t = threading.Thread(target=serve, args=(srv, log)); t.start()
    cl = socket.create_connection(("127.0.0.1", port)); cl.sendall(data)
    cl.sendall(b"\x10\x04\x01"); r1 = cl.recv(1)
    cl.sendall(b"\x10\x04\x04"); r4 = cl.recv(1)
    cl.close(); t.join()
    rec = log[0]
    print("port", port, "sent", len(data) + 6, "recorded", len(rec), "status n=1 ->", r1.hex(), "n=4 ->", r4.hex())
    print("recorded stream starts with ESC @:", rec.startswith(b"\x1b\x40"), "| contains ESC p 00 19 fa:", b"\x1b\x70\x00\x19\xfa" in rec)
