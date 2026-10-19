//go:build js && wasm

package main

import (
	"encoding/json"
	"syscall/js"
)

// Exposes kodeeboAmount(jsonString) -> Number on the JS global object, then blocks so the callback stays alive.
func main() {
	js.Global().Set("kodeeboAmount", js.FuncOf(func(this js.Value, a []js.Value) any {
		var c Case
		if err := json.Unmarshal([]byte(a[0].String()), &c); err != nil {
			return -1
		}
		return float64(Amount(c))
	}))
	select {}
}
