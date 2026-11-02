import 'package:chat_app/models/chat_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ChatUser round-trips through a document map', () {
    final user = ChatUser(
      uid: 'abc',
      email: 'a@b.com',
      username: 'Anna',
      imageUrl: 'https://example.com/a.jpg',
    );
    final copy = ChatUser.fromMap('abc', user.toMap());
    expect(copy.username, 'Anna');
    expect(copy.imageUrl, user.imageUrl);
  });
}
