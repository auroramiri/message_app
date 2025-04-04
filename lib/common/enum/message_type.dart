enum MessageType {
  text('text'),
  image('image'),
  audio('audio'),
  video('video'),
  file('file'),
  gif('gif');

  final String type;

  const MessageType(this.type);
}

extension ConvertMessage on String {
  MessageType toEnum() {
    switch (this) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      case 'file':
        return MessageType.file;
      case 'gif':
        return MessageType.gif;

      default:
        return MessageType.text;
    }
  }
}
