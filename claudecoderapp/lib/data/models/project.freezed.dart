// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Project _$ProjectFromJson(Map<String, dynamic> json) {
  return _Project.fromJson(json);
}

/// @nodoc
mixin _$Project {
  String get name => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String get fullPath => throw _privateConstructorUsedError;
  List<Session> get sessions => throw _privateConstructorUsedError;
  Map<String, dynamic>? get sessionMeta => throw _privateConstructorUsedError;
  @JsonKey(name: 'cursorSessions')
  List<Session> get cursorSessions => throw _privateConstructorUsedError;

  /// Serializes this Project to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectCopyWith<Project> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectCopyWith<$Res> {
  factory $ProjectCopyWith(Project value, $Res Function(Project) then) =
      _$ProjectCopyWithImpl<$Res, Project>;
  @useResult
  $Res call({
    String name,
    String displayName,
    String fullPath,
    List<Session> sessions,
    Map<String, dynamic>? sessionMeta,
    @JsonKey(name: 'cursorSessions') List<Session> cursorSessions,
  });
}

/// @nodoc
class _$ProjectCopyWithImpl<$Res, $Val extends Project>
    implements $ProjectCopyWith<$Res> {
  _$ProjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? displayName = null,
    Object? fullPath = null,
    Object? sessions = null,
    Object? sessionMeta = freezed,
    Object? cursorSessions = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            fullPath: null == fullPath
                ? _value.fullPath
                : fullPath // ignore: cast_nullable_to_non_nullable
                      as String,
            sessions: null == sessions
                ? _value.sessions
                : sessions // ignore: cast_nullable_to_non_nullable
                      as List<Session>,
            sessionMeta: freezed == sessionMeta
                ? _value.sessionMeta
                : sessionMeta // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            cursorSessions: null == cursorSessions
                ? _value.cursorSessions
                : cursorSessions // ignore: cast_nullable_to_non_nullable
                      as List<Session>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProjectImplCopyWith<$Res> implements $ProjectCopyWith<$Res> {
  factory _$$ProjectImplCopyWith(
    _$ProjectImpl value,
    $Res Function(_$ProjectImpl) then,
  ) = __$$ProjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String displayName,
    String fullPath,
    List<Session> sessions,
    Map<String, dynamic>? sessionMeta,
    @JsonKey(name: 'cursorSessions') List<Session> cursorSessions,
  });
}

/// @nodoc
class __$$ProjectImplCopyWithImpl<$Res>
    extends _$ProjectCopyWithImpl<$Res, _$ProjectImpl>
    implements _$$ProjectImplCopyWith<$Res> {
  __$$ProjectImplCopyWithImpl(
    _$ProjectImpl _value,
    $Res Function(_$ProjectImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? displayName = null,
    Object? fullPath = null,
    Object? sessions = null,
    Object? sessionMeta = freezed,
    Object? cursorSessions = null,
  }) {
    return _then(
      _$ProjectImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        fullPath: null == fullPath
            ? _value.fullPath
            : fullPath // ignore: cast_nullable_to_non_nullable
                  as String,
        sessions: null == sessions
            ? _value._sessions
            : sessions // ignore: cast_nullable_to_non_nullable
                  as List<Session>,
        sessionMeta: freezed == sessionMeta
            ? _value._sessionMeta
            : sessionMeta // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        cursorSessions: null == cursorSessions
            ? _value._cursorSessions
            : cursorSessions // ignore: cast_nullable_to_non_nullable
                  as List<Session>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectImpl implements _Project {
  const _$ProjectImpl({
    required this.name,
    required this.displayName,
    required this.fullPath,
    final List<Session> sessions = const [],
    final Map<String, dynamic>? sessionMeta,
    @JsonKey(name: 'cursorSessions')
    final List<Session> cursorSessions = const [],
  }) : _sessions = sessions,
       _sessionMeta = sessionMeta,
       _cursorSessions = cursorSessions;

  factory _$ProjectImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectImplFromJson(json);

  @override
  final String name;
  @override
  final String displayName;
  @override
  final String fullPath;
  final List<Session> _sessions;
  @override
  @JsonKey()
  List<Session> get sessions {
    if (_sessions is EqualUnmodifiableListView) return _sessions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sessions);
  }

  final Map<String, dynamic>? _sessionMeta;
  @override
  Map<String, dynamic>? get sessionMeta {
    final value = _sessionMeta;
    if (value == null) return null;
    if (_sessionMeta is EqualUnmodifiableMapView) return _sessionMeta;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<Session> _cursorSessions;
  @override
  @JsonKey(name: 'cursorSessions')
  List<Session> get cursorSessions {
    if (_cursorSessions is EqualUnmodifiableListView) return _cursorSessions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cursorSessions);
  }

  @override
  String toString() {
    return 'Project(name: $name, displayName: $displayName, fullPath: $fullPath, sessions: $sessions, sessionMeta: $sessionMeta, cursorSessions: $cursorSessions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.fullPath, fullPath) ||
                other.fullPath == fullPath) &&
            const DeepCollectionEquality().equals(other._sessions, _sessions) &&
            const DeepCollectionEquality().equals(
              other._sessionMeta,
              _sessionMeta,
            ) &&
            const DeepCollectionEquality().equals(
              other._cursorSessions,
              _cursorSessions,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    displayName,
    fullPath,
    const DeepCollectionEquality().hash(_sessions),
    const DeepCollectionEquality().hash(_sessionMeta),
    const DeepCollectionEquality().hash(_cursorSessions),
  );

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      __$$ProjectImplCopyWithImpl<_$ProjectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectImplToJson(this);
  }
}

abstract class _Project implements Project {
  const factory _Project({
    required final String name,
    required final String displayName,
    required final String fullPath,
    final List<Session> sessions,
    final Map<String, dynamic>? sessionMeta,
    @JsonKey(name: 'cursorSessions') final List<Session> cursorSessions,
  }) = _$ProjectImpl;

  factory _Project.fromJson(Map<String, dynamic> json) = _$ProjectImpl.fromJson;

  @override
  String get name;
  @override
  String get displayName;
  @override
  String get fullPath;
  @override
  List<Session> get sessions;
  @override
  Map<String, dynamic>? get sessionMeta;
  @override
  @JsonKey(name: 'cursorSessions')
  List<Session> get cursorSessions;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
