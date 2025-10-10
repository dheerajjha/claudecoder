import 'package:freezed_annotation/freezed_annotation.dart';
import 'session.dart';

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
class Project with _$Project {
  const factory Project({
    required String name,
    required String displayName,
    required String fullPath,
    @Default([]) List<Session> sessions,
    Map<String, dynamic>? sessionMeta,
    @Default([]) @JsonKey(name: 'cursorSessions') List<Session> cursorSessions,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}
