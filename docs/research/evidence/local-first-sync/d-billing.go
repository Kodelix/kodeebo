// d-billing.go - Go reference of billing algorithm A (see d-billing-gen.py). Run: go run d-billing.go <vectors.json>
package main

import ("encoding/json"; "fmt"; "os")

type seg struct{ ElapsedMs int64 `json:"elapsed_ms"`; RatePPH int64 `json:"rate_pph"` }
type cs struct{ ID int `json:"id"`; Segs []seg `json:"segments"`; Min int64 `json:"min_billable_minutes"`; Inc int64 `json:"increment_minutes"`; Mode string `json:"mode"` }

func amount(c cs) int64 {
	var total, num int64
	for _, s := range c.Segs { total += s.ElapsedMs; num += s.ElapsedMs * s.RatePPH }
	unit := c.Inc * 60000
	f := total
	if m := c.Min * 60000; m > f { f = m }
	var r int64
	switch c.Mode {
	case "up": r = (f + unit - 1) / unit * unit
	case "down": r = f / unit * unit
	default: r = (2*f + unit) / (2 * unit) * unit
	}
	if m := c.Min * 60000; m > r { r = m }
	num += (r - total) * c.Segs[len(c.Segs)-1].RatePPH
	return floorDiv(2*num+3600000, 2*3600000)
}
func floorDiv(a, b int64) int64 { q := a / b; if (a%b != 0) && ((a < 0) != (b < 0)) { q-- }; return q }
func main() {
	b, _ := os.ReadFile(os.Args[1]); var cases []cs
	if err := json.Unmarshal(b, &cases); err != nil { panic(err) }
	for _, c := range cases { fmt.Printf("%d,%d\n", c.ID, amount(c)) }
}
