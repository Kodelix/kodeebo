package kodeebo.notifications.adapters
import fake.mail.MailClient
import java.net.http.HttpClient
import kodeebo.notifications.app.NotificationPort
import kodeebo.notifications.domain.Message
class MailAdapter(private val mail: MailClient = MailClient(), private val http: HttpClient = HttpClient.newHttpClient()) : NotificationPort {
    override fun send(message: Message) { mail.send(message.to); http.hashCode() }
}
