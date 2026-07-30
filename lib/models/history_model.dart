class HistoryModel {
  final String id;
  final String text;
  final String time;

  HistoryModel({
    required this.id,
    required this.text,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'time': time,
    };
  }

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      time: json['time'] ?? '',
    );
  }
}
