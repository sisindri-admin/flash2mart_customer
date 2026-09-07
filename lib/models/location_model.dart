class UserAddress {
  final String id;
  final String title; // Home, Work, Other
  final String houseNo;
  final String area;
  final String landmark;

  UserAddress({
    required this.id,
    required this.title,
    required this.houseNo,
    required this.area,
    required this.landmark,
  });

  String get fullAddress {
    List<String> parts = [];
    if (houseNo.isNotEmpty) parts.add(houseNo);
    if (area.isNotEmpty) parts.add(area);
    if (landmark.isNotEmpty) parts.add('Landmark: $landmark');
    return parts.join(', ');
  }
}