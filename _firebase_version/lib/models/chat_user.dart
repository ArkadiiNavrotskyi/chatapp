class ChatUser {
  final String uid;
  final String email;
  final String username;
  final String imageUrl; // Firebase Storage download URL

  ChatUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
    'email': email,
    'username': username,
    'imageUrl': imageUrl,
  };

  factory ChatUser.fromMap(String uid, Map<String, dynamic> data) => ChatUser(
    uid: uid,
    email: data['email'] as String? ?? '',
    username: data['username'] as String? ?? '',
    imageUrl: data['imageUrl'] as String? ?? '',
  );
}
