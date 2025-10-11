// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ChatMessage {
  String get id => throw _privateConstructorUsedError;
  String get role =>
      throw _privateConstructorUsedError; // 'user' or 'assistant'
  String get content => throw _privateConstructorUsedError;
  String? get timestamp => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  bool get isStreaming => throw _privateConstructorUsedError;
  bool? get isToolUse => throw _privateConstructorUsedError;
  String? get toolName => throw _privateConstructorUsedError;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
    ChatMessage value,
    $Res Function(ChatMessage) then,
  ) = _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
  @useResult
  $Res call({
    String id,
    String role,
    String content,
    String? timestamp,
    Map<String, dynamic>? metadata,
    bool isStreaming,
    bool? isToolUse,
    String? toolName,
  });
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? role = null,
    Object? content = null,
    Object? timestamp = freezed,
    Object? metadata = freezed,
    Object? isStreaming = null,
    Object? isToolUse = freezed,
    Object? toolName = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            timestamp: freezed == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as String?,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            isStreaming: null == isStreaming
                ? _value.isStreaming
                : isStreaming // ignore: cast_nullable_to_non_nullable
                      as bool,
            isToolUse: freezed == isToolUse
                ? _value.isToolUse
                : isToolUse // ignore: cast_nullable_to_non_nullable
                      as bool?,
            toolName: freezed == toolName
                ? _value.toolName
                : toolName // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
    _$ChatMessageImpl value,
    $Res Function(_$ChatMessageImpl) then,
  ) = __$$ChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String role,
    String content,
    String? timestamp,
    Map<String, dynamic>? metadata,
    bool isStreaming,
    bool? isToolUse,
    String? toolName,
  });
}

/// @nodoc
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
    _$ChatMessageImpl _value,
    $Res Function(_$ChatMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? role = null,
    Object? content = null,
    Object? timestamp = freezed,
    Object? metadata = freezed,
    Object? isStreaming = null,
    Object? isToolUse = freezed,
    Object? toolName = freezed,
  }) {
    return _then(
      _$ChatMessageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: freezed == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String?,
        metadata: freezed == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        isStreaming: null == isStreaming
            ? _value.isStreaming
            : isStreaming // ignore: cast_nullable_to_non_nullable
                  as bool,
        isToolUse: freezed == isToolUse
            ? _value.isToolUse
            : isToolUse // ignore: cast_nullable_to_non_nullable
                  as bool?,
        toolName: freezed == toolName
            ? _value.toolName
            : toolName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ChatMessageImpl implements _ChatMessage {
  const _$ChatMessageImpl({
    required this.id,
    required this.role,
    required this.content,
    this.timestamp,
    final Map<String, dynamic>? metadata,
    this.isStreaming = false,
    this.isToolUse,
    this.toolName,
  }) : _metadata = metadata;

  @override
  final String id;
  @override
  final String role;
  // 'user' or 'assistant'
  @override
  final String content;
  @override
  final String? timestamp;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey()
  final bool isStreaming;
  @override
  final bool? isToolUse;
  @override
  final String? toolName;

  @override
  String toString() {
    return 'ChatMessage(id: $id, role: $role, content: $content, timestamp: $timestamp, metadata: $metadata, isStreaming: $isStreaming, isToolUse: $isToolUse, toolName: $toolName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.isStreaming, isStreaming) ||
                other.isStreaming == isStreaming) &&
            (identical(other.isToolUse, isToolUse) ||
                other.isToolUse == isToolUse) &&
            (identical(other.toolName, toolName) ||
                other.toolName == toolName));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    role,
    content,
    timestamp,
    const DeepCollectionEquality().hash(_metadata),
    isStreaming,
    isToolUse,
    toolName,
  );

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);
}

abstract class _ChatMessage implements ChatMessage {
  const factory _ChatMessage({
    required final String id,
    required final String role,
    required final String content,
    final String? timestamp,
    final Map<String, dynamic>? metadata,
    final bool isStreaming,
    final bool? isToolUse,
    final String? toolName,
  }) = _$ChatMessageImpl;

  @override
  String get id;
  @override
  String get role; // 'user' or 'assistant'
  @override
  String get content;
  @override
  String? get timestamp;
  @override
  Map<String, dynamic>? get metadata;
  @override
  bool get isStreaming;
  @override
  bool? get isToolUse;
  @override
  String? get toolName;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WebSocketMessage _$WebSocketMessageFromJson(Map<String, dynamic> json) {
  return _WebSocketMessage.fromJson(json);
}

/// @nodoc
mixin _$WebSocketMessage {
  String get type => throw _privateConstructorUsedError;
  Map<String, dynamic>? get data => throw _privateConstructorUsedError;
  String? get sessionId => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this WebSocketMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WebSocketMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WebSocketMessageCopyWith<WebSocketMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WebSocketMessageCopyWith<$Res> {
  factory $WebSocketMessageCopyWith(
    WebSocketMessage value,
    $Res Function(WebSocketMessage) then,
  ) = _$WebSocketMessageCopyWithImpl<$Res, WebSocketMessage>;
  @useResult
  $Res call({
    String type,
    Map<String, dynamic>? data,
    String? sessionId,
    String? content,
    String? error,
  });
}

/// @nodoc
class _$WebSocketMessageCopyWithImpl<$Res, $Val extends WebSocketMessage>
    implements $WebSocketMessageCopyWith<$Res> {
  _$WebSocketMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WebSocketMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? data = freezed,
    Object? sessionId = freezed,
    Object? content = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            data: freezed == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            sessionId: freezed == sessionId
                ? _value.sessionId
                : sessionId // ignore: cast_nullable_to_non_nullable
                      as String?,
            content: freezed == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String?,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WebSocketMessageImplCopyWith<$Res>
    implements $WebSocketMessageCopyWith<$Res> {
  factory _$$WebSocketMessageImplCopyWith(
    _$WebSocketMessageImpl value,
    $Res Function(_$WebSocketMessageImpl) then,
  ) = __$$WebSocketMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String type,
    Map<String, dynamic>? data,
    String? sessionId,
    String? content,
    String? error,
  });
}

/// @nodoc
class __$$WebSocketMessageImplCopyWithImpl<$Res>
    extends _$WebSocketMessageCopyWithImpl<$Res, _$WebSocketMessageImpl>
    implements _$$WebSocketMessageImplCopyWith<$Res> {
  __$$WebSocketMessageImplCopyWithImpl(
    _$WebSocketMessageImpl _value,
    $Res Function(_$WebSocketMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WebSocketMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? data = freezed,
    Object? sessionId = freezed,
    Object? content = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _$WebSocketMessageImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        data: freezed == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        sessionId: freezed == sessionId
            ? _value.sessionId
            : sessionId // ignore: cast_nullable_to_non_nullable
                  as String?,
        content: freezed == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String?,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WebSocketMessageImpl implements _WebSocketMessage {
  const _$WebSocketMessageImpl({
    required this.type,
    final Map<String, dynamic>? data,
    this.sessionId,
    this.content,
    this.error,
  }) : _data = data;

  factory _$WebSocketMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$WebSocketMessageImplFromJson(json);

  @override
  final String type;
  final Map<String, dynamic>? _data;
  @override
  Map<String, dynamic>? get data {
    final value = _data;
    if (value == null) return null;
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? sessionId;
  @override
  final String? content;
  @override
  final String? error;

  @override
  String toString() {
    return 'WebSocketMessage(type: $type, data: $data, sessionId: $sessionId, content: $content, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WebSocketMessageImpl &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    const DeepCollectionEquality().hash(_data),
    sessionId,
    content,
    error,
  );

  /// Create a copy of WebSocketMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WebSocketMessageImplCopyWith<_$WebSocketMessageImpl> get copyWith =>
      __$$WebSocketMessageImplCopyWithImpl<_$WebSocketMessageImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$WebSocketMessageImplToJson(this);
  }
}

abstract class _WebSocketMessage implements WebSocketMessage {
  const factory _WebSocketMessage({
    required final String type,
    final Map<String, dynamic>? data,
    final String? sessionId,
    final String? content,
    final String? error,
  }) = _$WebSocketMessageImpl;

  factory _WebSocketMessage.fromJson(Map<String, dynamic> json) =
      _$WebSocketMessageImpl.fromJson;

  @override
  String get type;
  @override
  Map<String, dynamic>? get data;
  @override
  String? get sessionId;
  @override
  String? get content;
  @override
  String? get error;

  /// Create a copy of WebSocketMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WebSocketMessageImplCopyWith<_$WebSocketMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
