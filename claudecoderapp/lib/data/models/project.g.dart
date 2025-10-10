// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectImpl _$$ProjectImplFromJson(Map<String, dynamic> json) =>
    _$ProjectImpl(
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      fullPath: json['fullPath'] as String,
      sessions:
          (json['sessions'] as List<dynamic>?)
              ?.map((e) => Session.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sessionMeta: json['sessionMeta'] as Map<String, dynamic>?,
      cursorSessions:
          (json['cursorSessions'] as List<dynamic>?)
              ?.map((e) => Session.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ProjectImplToJson(_$ProjectImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'displayName': instance.displayName,
      'fullPath': instance.fullPath,
      'sessions': instance.sessions,
      'sessionMeta': instance.sessionMeta,
      'cursorSessions': instance.cursorSessions,
    };
