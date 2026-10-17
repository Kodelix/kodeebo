package main

import (
	"crypto/ed25519"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"runtime"

	circl "github.com/cloudflare/circl/sign/ed25519"
)

type V struct{ Name, Pub, Msg, Sig string }

func try(f func() bool) (r string) {
	defer func() {
		if e := recover(); e != nil {
			r = fmt.Sprintf("PANIC(%v)", e)
		}
	}()
	return fmt.Sprint(f())
}
func main() {
	b, _ := os.ReadFile(os.Args[1])
	var vs []V
	_ = json.Unmarshal(b, &vs)
	fmt.Println("runtime", runtime.Version())
	for _, v := range vs {
		p, _ := hex.DecodeString(v.Pub)
		m, _ := hex.DecodeString(v.Msg)
		s, _ := hex.DecodeString(v.Sig)
		fmt.Printf("%-55s go-stdlib=%-40s circl=%s\n", v.Name,
			try(func() bool { return ed25519.Verify(p, m, s) }),
			try(func() bool { return circl.Verify(p, m, s) }))
	}
}
