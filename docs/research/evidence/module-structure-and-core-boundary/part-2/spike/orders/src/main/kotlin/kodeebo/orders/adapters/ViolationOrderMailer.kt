package kodeebo.orders.adapters
// R1a violation: mail client outside Notifications
import fake.mail.MailClient
class OrderMailer(val m: MailClient)
