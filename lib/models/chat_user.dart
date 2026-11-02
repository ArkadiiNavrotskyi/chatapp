class ChatUser {
  final String uid;
  final String email;
  final String username;
  final String imageUrl; // URL returned by LocalStorage.putData

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
