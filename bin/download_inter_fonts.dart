import 'dart:io';

void main() async {
  final fonts = [
    'Inter-ExtraBold.ttf',
    'Inter-Light.ttf',
    'Inter-ExtraLight.ttf',
    'Inter-Thin.ttf',
    'Inter-Black.ttf'
  ];
  final baseUrl = 'https://raw.githubusercontent.com/googlefonts/inter/main/fonts/ttf/';
  final dir = Directory('assets/google_fonts');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final client = HttpClient();
  
  for (final font in fonts) {
    print('Downloading \$font...');
    try {
      final request = await client.getUrl(Uri.parse('\$baseUrl\$font'));
      final response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        final file = File('\${dir.path}/\$font');
        final builder = BytesBuilder();
        await for (var chunk in response) {
          builder.add(chunk);
        }
        await file.writeAsBytes(builder.takeBytes());
        print('Saved \$font.');
      } else {
        print('Failed to download \$font. Status: \${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading \$font: \$e');
    }
  }
  
  client.close();
}
