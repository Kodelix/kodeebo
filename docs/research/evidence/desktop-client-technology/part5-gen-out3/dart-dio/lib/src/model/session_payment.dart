//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/wallet.dart';
import 'package:openapi/src/model/cash.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';

part 'session_payment.g.dart';

/// SessionPayment
///
/// Properties:
/// * [kind] 
@BuiltValue()
abstract class SessionPayment implements Built<SessionPayment, SessionPaymentBuilder> {
  /// One Of [Cash], [Wallet]
  OneOf get oneOf;

  static const String discriminatorFieldName = r'kind';

  static const Map<String, Type> discriminatorMapping = {
    r'Cash': Cash,
    r'Wallet': Wallet,
  };

  SessionPayment._();

  factory SessionPayment([void updates(SessionPaymentBuilder b)]) = _$SessionPayment;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SessionPaymentBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SessionPayment> get serializer => _$SessionPaymentSerializer();
}

extension SessionPaymentDiscriminatorExt on SessionPayment {
    String? get discriminatorValue {
        if (this is Cash) {
            return r'Cash';
        }
        if (this is Wallet) {
            return r'Wallet';
        }
        return null;
    }
}
extension SessionPaymentBuilderDiscriminatorExt on SessionPaymentBuilder {
    String? get discriminatorValue {
        if (this is CashBuilder) {
            return r'Cash';
        }
        if (this is WalletBuilder) {
            return r'Wallet';
        }
        return null;
    }
}

class _$SessionPaymentSerializer implements PrimitiveSerializer<SessionPayment> {
  @override
  final Iterable<Type> types = const [SessionPayment, _$SessionPayment];

  @override
  final String wireName = r'SessionPayment';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SessionPayment object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
  }

  @override
  Object serialize(
    Serializers serializers,
    SessionPayment object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(oneOf.value, specifiedType: FullType(oneOf.valueType))!;
  }

  @override
  SessionPayment deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SessionPaymentBuilder();
    Object? oneOfDataSrc;
    final serializedList = (serialized as Iterable<Object?>).toList();
    final discIndex = serializedList.indexOf(SessionPayment.discriminatorFieldName) + 1;
    final discValue = serializers.deserialize(serializedList[discIndex], specifiedType: FullType(String)) as String;
    oneOfDataSrc = serialized;
    final oneOfTypes = [Cash, Wallet, ];
    Object oneOfResult;
    Type oneOfType;
    switch (discValue) {
      case r'Cash':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(Cash),
        ) as Cash;
        oneOfType = Cash;
        break;
      case r'Wallet':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(Wallet),
        ) as Wallet;
        oneOfType = Wallet;
        break;
      default:
        throw UnsupportedError("Couldn't deserialize oneOf for the discriminator value: ${discValue}");
    }
    result.oneOf = OneOfDynamic(typeIndex: oneOfTypes.indexOf(oneOfType), types: oneOfTypes, value: oneOfResult);
    return result.build();
  }
}


