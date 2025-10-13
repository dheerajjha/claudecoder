class GitStatus {
  final String branch;
  final List<String> modified;
  final List<String> added;
  final List<String> deleted;
  final List<String> untracked;
  final String? error;

  GitStatus({
    required this.branch,
    required this.modified,
    required this.added,
    required this.deleted,
    required this.untracked,
    this.error,
  });

  factory GitStatus.fromJson(Map<String, dynamic> json) {
    return GitStatus(
      branch: json['branch'] ?? '',
      modified: List<String>.from(json['modified'] ?? []),
      added: List<String>.from(json['added'] ?? []),
      deleted: List<String>.from(json['deleted'] ?? []),
      untracked: List<String>.from(json['untracked'] ?? []),
      error: json['error'],
    );
  }

  bool get hasChanges =>
      modified.isNotEmpty ||
      added.isNotEmpty ||
      deleted.isNotEmpty ||
      untracked.isNotEmpty;

  int get totalChanges =>
      modified.length + added.length + deleted.length + untracked.length;
}

class GitDiff {
  final String diff;
  final String? error;

  GitDiff({
    required this.diff,
    this.error,
  });

  factory GitDiff.fromJson(Map<String, dynamic> json) {
    return GitDiff(
      diff: json['diff'] ?? '',
      error: json['error'],
    );
  }
}
