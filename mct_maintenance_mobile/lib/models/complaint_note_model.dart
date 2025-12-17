class ComplaintNote {
  final String id;
  final String complaintId;
  final String note;
  final DateTime createdAt;
  final String? authorName;
  final String? authorRole;

  ComplaintNote({
    required this.id,
    required this.complaintId,
    required this.note,
    required this.createdAt,
    this.authorName,
    this.authorRole,
  });

  factory ComplaintNote.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String? authorName;
    if (user != null) {
      final firstName = user['first_name'] ?? '';
      final lastName = user['last_name'] ?? '';
      authorName = '$firstName $lastName'.trim();
      if (authorName.isEmpty) authorName = null;
    }

    return ComplaintNote(
      id: json['id']?.toString() ?? '',
      complaintId: json['complaintId']?.toString() ?? json['complaint_id']?.toString() ?? '',
      note: json['note'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      authorName: authorName,
      authorRole: user?['role'],
    );
  }
}
