import 'dart:convert';

void main() {
  Map<String, dynamic> reportData = {
    'work_description': 'test',
    'duration': '1h',
    'equipments': [{'name': 'Clim 1', 'freon': 'R410'}],
  };

  final fields = <String, String>{};
  reportData.forEach((key, value) {
    if (value != null) {
      if (key == 'photos') {
      } else if (value is List || value is Map) {
        fields[key] = jsonEncode(value);
      } else {
        fields[key] = value.toString();
      }
    }
  });

  print(fields);
}
