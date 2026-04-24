class Circle {
  final String id;
  final String name;
  final String inviteCode;
  final String adminId;
  final List<String> members;

  Circle({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.adminId,
    required this.members,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'inviteCode': inviteCode,
      'adminId': adminId,
      'members': members,
    };
  }

  factory Circle.fromMap(String id, Map<String, dynamic> map) {
    return Circle(
      id: id,
      name: map['name'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      adminId: map['adminId'] ?? '',
      members: List<String>.from(map['members'] ?? []),
    );
  }
}
