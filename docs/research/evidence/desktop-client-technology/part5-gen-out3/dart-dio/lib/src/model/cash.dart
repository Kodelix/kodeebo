//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'cash.g.dart';

/// Cash
///
/// Properties:
/// * [kind] 
@BuiltValue()
abstract class Cash implements Built<Cash, CashBuilder> {
  @BuiltValueField(wireName: r'kind')
  String get kind;

  Cash._();

  factory Cash([void updates(CashBuilder b)]) = _$Cash;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CashBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Cash> get serializer => _$CashSerializer();
}

class _$CashSerializer implements PrimitiveSerializer<Cash> {
  @override
  final Iterable<Type> types = const [Cash, _$Cash];

  @override
  final String wireName = r'Cash';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Cash object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Cash object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CashBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'kind':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.kind = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Cash deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CashBuilder();
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


