// main.go - Go x/text formatting. Money is an int64 piasters value; x/text has no currency formatter that takes ISO code EGP from CLDR in message.Printer for this, so the test prints number.Decimal and the currency via x/text/currency.
package main

import (
	"fmt"
	"golang.org/x/text/currency"
	"golang.org/x/text/language"
	"golang.org/x/text/message"
	"golang.org/x/text/number"
)

func main() {
	for _, tag := range []string{"ar-EG", "ar-EG-u-nu-latn", "en-EG", "en-US"} {
		t := language.MustParse(tag)
		p := message.NewPrinter(t)
		fmt.Printf("%s decimal(1234567.5)=%s  currency=%s\n", tag, p.Sprint(number.Decimal(1234567.5)), p.Sprint(currency.Symbol(currency.EGP.Amount(1234567.5))))
	}
}
