package net.kodelix.core.notifications.adapters
import fake.mail.MailClient
import java.net.http.HttpClient
import net.kodelix.core.notifications.app.NotificationPort
import net.kodelix.core.notifications.domain.Message
class MailAdapter(private val mail: MailClient = MailClient(), private val http: HttpClient = HttpClient.newHttpClient()) : NotificationPort {
    override fun send(message: Message) { mail.send(message.to); http.hashCode() }
}
