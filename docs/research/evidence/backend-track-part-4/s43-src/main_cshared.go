//go:build !js

package main

/*
#include <stdlib.h>
*/
import "C"

import "encoding/json"

// KodeeboAmount takes a JSON case (NUL-terminated UTF-8) and returns the amount in piasters, or -1 on a parse error.
//
//export KodeeboAmount
func KodeeboAmount(js *C.char) C.longlong {
	var c Case
	if err := json.Unmarshal([]byte(C.GoString(js)), &c); err != nil {
		return -1
	}
	return C.longlong(Amount(c))
}

func main() {}
