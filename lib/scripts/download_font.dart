import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://fonts.gstatic.com/s/poppins/v20/pxiByp8kv8JHgFVrLCz7Z1xlFd2JQEk.woff2');
  final response = await http.get(url);
  final file = File('assets/google_fonts/Poppins-ExtraBold.ttf');
  await file.writeAsBytes(response.bodyBytes);
  print('Downloaded Poppins-ExtraBold');
}
