class GitStatus {
  final String branch;
  final List<String> modified;
  final List<String> added;
  final List<String> deleted;
  final List<String> untracked;
  final int ahead;
  final String? error;

  GitStatus({
    required this.branch,
    required this.modified,
    required this.added,
    required this.deleted,
    required this.untracked,
    this.ahead = 0,
    this.error,
  });

  factory GitStatus.fromJson(Map<String, dynamic> json) {
    return GitStatus(
      branch: json['branch'] ?? '',
      modified: List<String>.from(json['modified'] ?? []),
      added: List<String>.from(json['added'] ?? []),
      deleted: List<String>.from(json['deleted'] ?? []),
      untracked: List<String>.from(json['untracked'] ?? []),
      ahead: json['ahead'] ?? 0,
      error: json['error'],
    );
  }

  bool get hasChanges =>
      modified.isNotEmpty ||
      added.isNotEmpty ||
      deleted.isNotEmpty ||
      untracked.isNotEmpty;

  bool get hasUnpushedCommits => ahead > 0;

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
