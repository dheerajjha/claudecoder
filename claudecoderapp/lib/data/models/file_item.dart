import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_item.freezed.dart';
part 'file_item.g.dart';

@freezed
class FileItem with _$FileItem {
  const factory FileItem({
    required String name,
    required String path,
    required String type, // 'file' or 'directory'
    int? size,
    String? modified,
    @Default([]) List<FileItem> children,
  }) = _FileItem;

  factory FileItem.fromJson(Map<String, dynamic> json) =>
      _$FileItemFromJson(json);
}
