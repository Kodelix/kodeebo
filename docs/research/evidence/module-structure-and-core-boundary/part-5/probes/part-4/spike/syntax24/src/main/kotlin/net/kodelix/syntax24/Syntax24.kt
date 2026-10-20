package net.kodelix.syntax24

import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

annotation class Marker

class UserService {
    fun name(id: Int): String = "u$id"
}

// Context parameters (stable in Kotlin 2.4.0 per the stack reference)
context(users: UserService)
fun greet(id: Int): String = "hello " + users.name(id)

fun demo(): String = with(UserService()) { greet(1) }

// Explicit backing field (stable in Kotlin 2.4.0 per the stack reference)
class Cart {
    val items: List<String>
        field = mutableListOf<String>()

    fun add(item: String) {
        items.add(item)
    }
}

sealed interface Shape

data class Circle(
    val r: Int,
) : Shape

data class Square(
    val s: Int,
) : Shape

// `when` guard condition (stable since Kotlin 2.2)
fun area(shape: Shape): Int =
    when (shape) {
        is Circle if shape.r > 0 -> shape.r * shape.r * 3
        is Circle -> 0
        is Square -> shape.s * shape.s
    }

// Multi-dollar interpolation (stable since Kotlin 2.2)
fun template(total: Int): String = $$"""{"cost": $${total + 1}, "literal": $total}"""

// Nested type alias (stable since Kotlin 2.3.0 per the stack reference)
class Holder {
    typealias Id = String

    fun id(): Id = "x"
}

// `@all` meta-target (Kotlin 2.4.0 per the stack reference)
class Tagged(
    @all:Marker val x: Int,
)

@OptIn(ExperimentalUuidApi::class)
fun newId(): Uuid = Uuid.random()
