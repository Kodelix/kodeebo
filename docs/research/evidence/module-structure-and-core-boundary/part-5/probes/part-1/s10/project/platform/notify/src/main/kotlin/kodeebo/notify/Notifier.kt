package kodeebo.notify

import kodeebo.ratelimit.RateLimiter

/** Port: notifications. */
public interface Notifier {
    public fun send(to: String, body: String): Boolean
}

internal class RateLimitedNotifier(private val limiter: RateLimiter, private val inner: Notifier) : Notifier {
    override fun send(to: String, body: String): Boolean = limiter.tryAcquire(to) && inner.send(to, body)
}
