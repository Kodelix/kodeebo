// Probe server for research note backend-track part 1 (spike S10). Scratch code, not product code.
// Stdlib only. Same JSON shape as the Ktor probe (scripts/ktor-probe).
package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"runtime"
	"runtime/debug"
	"strconv"
)

type Line struct {
	SKU   string `json:"sku"`
	Qty   int    `json:"qty"`
	Price int64  `json:"price_piastres"`
}

type Order struct {
	ID     int    `json:"id"`
	Tenant string `json:"tenant"`
	Status string `json:"status"`
	Lines  []Line `json:"lines"`
}

func orders(n int) []Order {
	out := make([]Order, n)
	for i := range out {
		out[i] = Order{ID: i, Tenant: "tenant-" + strconv.Itoa(i%10), Status: "paid",
			Lines: []Line{{"coffee", 2, 4500}, {"ps5-hour", 1, 6000}, {"water", 3, 1000}}}
	}
	return out
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /ping", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"ok":true}`))
	})
	mux.HandleFunc("GET /orders", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(orders(50))
	})
	mux.HandleFunc("GET /info", func(w http.ResponseWriter, r *http.Request) {
		var m runtime.MemStats
		runtime.ReadMemStats(&m)
		lim := debug.SetMemoryLimit(-1)
		fmt.Fprintf(w, `{"gomaxprocs":%d,"numcpu":%d,"go":"%s","gomemlimit":%d,"heap_sys":%d,"heap_inuse":%d,"sys":%d,"num_gc":%d}`,
			runtime.GOMAXPROCS(0), runtime.NumCPU(), runtime.Version(), lim, m.HeapSys, m.HeapInuse, m.Sys, m.NumGC)
	})
	http.ListenAndServe(":8080", mux)
}
