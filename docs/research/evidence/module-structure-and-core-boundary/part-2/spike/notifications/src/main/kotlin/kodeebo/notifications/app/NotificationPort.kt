package kodeebo.notifications.app
import kodeebo.notifications.domain.Message
interface NotificationPort { fun send(message: Message) }
