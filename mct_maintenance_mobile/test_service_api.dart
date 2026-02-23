import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Test avec différentes configurations d'IP
  final testUrls = [
    'http://192.168.1.139:3000/api/installation-services/active',
    'http://192.168.1.4:3000/api/installation-services/active',
    'http://localhost:3000/api/installation-services/active',
    'http://10.0.2.2:3000/api/installation-services/active', // For Android emulator
  ];

  print('🔍 Testing API endpoints...\n');

  for (final url in testUrls) {
    print('Testing: $url');
    try {
      final response = await http.get(Uri.parse(url))
          .timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ SUCCESS - Status: ${response.statusCode}');
        print('   Data count: ${data.length}');
        print('   First item: ${data.isNotEmpty ? data[0]['title'] : 'empty'}');
      } else {
        print('❌ FAILED - Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ERROR: $e');
    }
    print('');
  }
}
