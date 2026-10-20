package kodeebo.ratelimit

/** Port: rate limiter. */
public interface RateLimiter {
    public fun tryAcquire(key: String): Boolean
}
