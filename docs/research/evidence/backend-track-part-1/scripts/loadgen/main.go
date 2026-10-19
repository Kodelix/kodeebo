// Closed-loop HTTP load generator for research note backend-track part 1. Scratch code.
// Usage: loadgen -url URL -c CONCURRENCY -d SECONDS
package main

import (
	"flag"
	"fmt"
	"io"
	"net/http"
	"sort"
	"sync"
	"time"
)

func main() {
	url := flag.String("url", "", "target URL")
	c := flag.Int("c", 16, "concurrent clients")
	d := flag.Int("d", 10, "seconds")
	flag.Parse()
	tr := &http.Transport{MaxIdleConnsPerHost: *c, MaxConnsPerHost: *c}
	cl := &http.Client{Transport: tr, Timeout: 10 * time.Second}
	deadline := time.Now().Add(time.Duration(*d) * time.Second)
	var mu sync.Mutex
	var lat []time.Duration
	errs := 0
	var wg sync.WaitGroup
	for i := 0; i < *c; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			var local []time.Duration
			e := 0
			for time.Now().Before(deadline) {
				t0 := time.Now()
				resp, err := cl.Get(*url)
				if err != nil {
					e++
					continue
				}
				io.Copy(io.Discard, resp.Body)
				resp.Body.Close()
				if resp.StatusCode != 200 {
					e++
					continue
				}
				local = append(local, time.Since(t0))
			}
			mu.Lock()
			lat = append(lat, local...)
			errs += e
			mu.Unlock()
		}()
	}
	wg.Wait()
	sort.Slice(lat, func(i, j int) bool { return lat[i] < lat[j] })
	p := func(q float64) time.Duration {
		if len(lat) == 0 {
			return 0
		}
		return lat[int(float64(len(lat)-1)*q)]
	}
	fmt.Printf(`{"url":"%s","clients":%d,"seconds":%d,"requests":%d,"errors":%d,"rps":%.0f,"p50_ms":%.2f,"p95_ms":%.2f,"p99_ms":%.2f}`+"\n",
		*url, *c, *d, len(lat), errs, float64(len(lat))/float64(*d),
		float64(p(0.5).Microseconds())/1000, float64(p(0.95).Microseconds())/1000, float64(p(0.99).Microseconds())/1000)
}
