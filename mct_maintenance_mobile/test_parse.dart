import 'dart:convert';

void main() {
  String jsonStr = '{"equipments": "[{\\"name\\": \\"Test\\"}]"}';
  var data = jsonDecode(jsonStr);
  print(data['equipments'].runtimeType);
  
  if (data['equipments'] is String) {
     var equipments = jsonDecode(data['equipments']);
     print(equipments.runtimeType);
  }
}
