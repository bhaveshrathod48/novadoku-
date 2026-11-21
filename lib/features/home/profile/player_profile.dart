import 'package:flutter/widgets.dart' show StringCharacters;

enum ProfileAvatar { nova, panda, fox, bunny, lion, koala, penguin, bear }

enum ProfileFrame {
  classicPurple,
  royalGold,
  rose,
  mint,
  cosmic,
  frost,
  sunshine,
  rainbow,
}

/// A separate, versioned save; profile edits never touch puzzle progress.
final class PlayerProfile {
  const PlayerProfile({
    this.username = 'Nova',
    this.avatar = ProfileAvatar.nova,
    this.frame = ProfileFrame.classicPurple,
  });

  final String username;
  final ProfileAvatar avatar;
  final ProfileFrame frame;

  static bool validName(String value) =>
      value.trim().isNotEmpty &&
      value.trim().characters.length <= 32 &&
      !RegExp(r'[\x00-\x1f\x7f]').hasMatch(value);

  Map<String, dynamic> toJson() => {
    'version': 1,
    'username': username,
    'avatar': avatar.name,
    'frame': frame.name,
  };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final name = json['username'];
    if (json['version'] != 1 || name is! String || !validName(name)) {
      throw const FormatException('Invalid profile save.');
    }
    final avatar = ProfileAvatar.values
        .where((v) => v.name == json['avatar'])
        .firstOrNull;
    final frame = ProfileFrame.values
        .where((v) => v.name == json['frame'])
        .firstOrNull;
    if (avatar == null || frame == null) {
      throw const FormatException('Unknown profile selection.');
    }
    return PlayerProfile(username: name.trim(), avatar: avatar, frame: frame);
  }
}
