// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SessionImpl _$$SessionImplFromJson(Map<String, dynamic> json) =>
    _$SessionImpl(
      id: json['id'] as String,
      title: json['title'] as String?,
      createdAt: json['createdAt'] as String?,
      lastActivity: json['lastActivity'] as String?,
      messageCount: (json['message_count'] as num?)?.toInt(),
      provider: json['provider'] as String? ?? 'claude',
    );

Map<String, dynamic> _$$SessionImplToJson(_$SessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'createdAt': instance.createdAt,
      'lastActivity': instance.lastActivity,
      'message_count': instance.messageCount,
      'provider': instance.provider,
    };
