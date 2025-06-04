class GroupChatModel {
  final String groupId;
  final String groupName;
  final String? groupIconUrl;
  final String createdBy;
  final List<String> participantIds;
  final List<String> moderatorIds;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  GroupChatModel({
    required this.groupId,
    required this.groupName,
    required this.groupIconUrl,
    required this.createdBy,
    required this.participantIds,
    required this.moderatorIds,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupIconUrl': groupIconUrl,
      'createdBy': createdBy,
      'participantIds': participantIds,
      'moderatorIds': moderatorIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
    };
  }

  factory GroupChatModel.fromMap(Map<String, dynamic> map) {
    return GroupChatModel(
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? '',
      groupIconUrl: map['groupIconUrl'],
      createdBy: map['createdBy'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      moderatorIds: List<String>.from(
        map['moderatorIds'] ?? [],
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastMessage: map['lastMessage'],
      lastMessageTime:
          map['lastMessageTime'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
              : null,
    );
  }
}
