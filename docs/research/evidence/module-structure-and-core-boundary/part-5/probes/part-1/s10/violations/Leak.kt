package kodeebo.app

import kodeebo.ratelimit.RateLimiter   // notify declares ratelimit as `implementation`: must NOT be visible here

internal fun leak(r: RateLimiter) = r.tryAcquire("x")
