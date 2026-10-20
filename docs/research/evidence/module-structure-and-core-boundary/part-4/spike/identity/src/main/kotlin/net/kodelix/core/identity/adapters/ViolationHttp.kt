package net.kodelix.core.identity.adapters
// R1b violation: JDK HTTP client outside Notifications
import java.net.http.HttpClient
class WebhookCaller { val client: HttpClient = HttpClient.newHttpClient() }
