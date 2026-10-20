package net.kodelix.core.notifications.app
import net.kodelix.core.notifications.domain.Message
interface NotificationPort { fun send(message: Message) }
