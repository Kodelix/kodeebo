//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/session_payment.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'session.g.dart';

/// Session
///
/// Properties:
/// * [id] 
/// * [state] 
/// * [amountMinor] 
/// * [startedAt] 
/// * [payment] 
@BuiltValue()
abstract class Session implements Built<Session, SessionBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'state')
  SessionStateEnum get state;
  // enum stateEnum {  open,  closed,  voided,  };

  @BuiltValueField(wireName: r'amountMinor')
  int get amountMinor;

  @BuiltValueField(wireName: r'startedAt')
  DateTime get startedAt;

  @BuiltValueField(wireName: r'payment')
  SessionPayment? get payment;

  Session._();

  factory Session([void updates(SessionBuilder b)]) = _$Session;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SessionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Session> get serializer => _$SessionSerializer();
}

class _$SessionSerializer implements PrimitiveSerializer<Session> {
  @override
  final Iterable<Type> types = const [Session, _$Session];

  @override
  final String wireName = r'Session';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Session object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'state';
    yield serializers.serialize(
      object.state,
      specifiedType: const FullType(SessionStateEnum),
    );
    yield r'amountMinor';
    yield serializers.serialize(
      object.amountMinor,
      specifiedType: const FullType(int),
    );
    yield r'startedAt';
    yield serializers.serialize(
      object.startedAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.payment != null) {
      yield r'payment';
      yield serializers.serialize(
        object.payment,
        specifiedType: const FullType(SessionPayment),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    Session object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SessionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(SessionStateEnum),
          ) as SessionStateEnum;
          result.state = valueDes;
          break;
        case r'amountMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.amountMinor = valueDes;
          break;
        case r'startedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.startedAt = valueDes;
          break;
        case r'payment':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(SessionPayment),
          ) as SessionPayment?;
          if (valueDes == null) continue;
          result.payment.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Session deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SessionBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}


class SessionStateEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'open')
  static const SessionStateEnum open = _$sessionStateEnum_open;
  @BuiltValueEnumConst(wireName: r'closed')
  static const SessionStateEnum closed = _$sessionStateEnum_closed;
  @BuiltValueEnumConst(wireName: r'voided')
  static const SessionStateEnum voided = _$sessionStateEnum_voided;

  static Serializer<SessionStateEnum> get serializer => _$sessionStateEnumSerializer;

  const SessionStateEnum._(String name): super(name);

  static BuiltSet<SessionStateEnum> get values => _$sessionStateEnumValues;
  static SessionStateEnum valueOf(String name) => _$sessionStateEnumValueOf(name);
}

