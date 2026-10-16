//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'wallet.g.dart';

/// Wallet
///
/// Properties:
/// * [kind] 
@BuiltValue()
abstract class Wallet implements Built<Wallet, WalletBuilder> {
  @BuiltValueField(wireName: r'kind')
  String get kind;

  Wallet._();

  factory Wallet([void updates(WalletBuilder b)]) = _$Wallet;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WalletBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Wallet> get serializer => _$WalletSerializer();
}

class _$WalletSerializer implements PrimitiveSerializer<Wallet> {
  @override
  final Iterable<Type> types = const [Wallet, _$Wallet];

  @override
  final String wireName = r'Wallet';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Wallet object, {
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
    Wallet object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required WalletBuilder result,
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
  Wallet deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WalletBuilder();
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


