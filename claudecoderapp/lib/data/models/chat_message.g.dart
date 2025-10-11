// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WebSocketMessageImpl _$$WebSocketMessageImplFromJson(
  Map<String, dynamic> json,
) => _$WebSocketMessageImpl(
  type: json['type'] as String,
  data: json['data'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String?,
  content: json['content'] as String?,
  error: json['error'] as String?,
);

Map<String, dynamic> _$$WebSocketMessageImplToJson(
  _$WebSocketMessageImpl instance,
) => <String, dynamic>{
  'type': instance.type,
  'data': instance.data,
  'sessionId': instance.sessionId,
  'content': instance.content,
  'error': instance.error,
};
