class FootfallData {
  final double lat;
  final double lng;
  final int count;
  final DateTime timestamp;

  FootfallData({
    required this.lat,
    required this.lng,
    required this.count,
    required this.timestamp,
  });

  factory FootfallData.fromJson(Map<String, dynamic> json) {
    return FootfallData(
      lat: json['lat'],
      lng: json['lng'],
      count: json['count'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
