// Neutral upstream echo for S25: prints every request header it receives as "HDR <name>: <value>"
// (Go net/http server, no framework). Stdlib only.
package main

import (
	"fmt"
	"net/http"
	"sort"
)

func main() {
	http.HandleFunc("/redir/", func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, "/t/cafe-slug/menu", http.StatusFound)
	})
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain")
		fmt.Fprintf(w, "UPSTREAM-SAW-PEER: %s\nUPSTREAM-SAW-URI: %s\n", r.RemoteAddr, r.RequestURI)
		keys := make([]string, 0, len(r.Header))
		for k := range r.Header {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		for _, k := range keys {
			fmt.Fprintf(w, "HDR %s: %s\n", k, r.Header[k][0])
		}
	})
	_ = http.ListenAndServe(":8080", nil)
}
