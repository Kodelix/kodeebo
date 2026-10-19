// main.go v2 (s46) - s45 failed to compile: currency.EGP is undefined in x/text/currency. Uses currency.MustParseISO("EGP") instead.
package main

import (
	"fmt"
	"golang.org/x/text/currency"
	"golang.org/x/text/language"
	"golang.org/x/text/message"
	"golang.org/x/text/number"
)

func main() {
	egp := currency.MustParseISO("EGP")
	for _, tag := range []string{"ar-EG", "ar-EG-u-nu-latn", "en-EG", "en-US"} {
		t := language.MustParse(tag)
		p := message.NewPrinter(t)
		fmt.Printf("%s decimal(1234567.5)=%s  currency(symbol)=%s  currency(iso)=%s\n", tag, p.Sprint(number.Decimal(1234567.5)), p.Sprint(currency.Symbol(egp.Amount(1234567.5))), p.Sprint(currency.ISO(egp.Amount(1234567.5))))
	}
}
