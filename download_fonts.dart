import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final fonts = {
    'inter': {'400': 'Inter-Regular.ttf', '500': 'Inter-Medium.ttf', '600': 'Inter-SemiBold.ttf', '700': 'Inter-Bold.ttf', '400i': 'Inter-Italic.ttf'},
    'roboto': {'400': 'Roboto-Regular.ttf', '500': 'Roboto-Medium.ttf', '700': 'Roboto-Bold.ttf'},
    'dm-sans': {'400': 'DMSans-Regular.ttf', '500': 'DMSans-Medium.ttf', '700': 'DMSans-Bold.ttf'}
  };

  final dir = Directory('assets/google_fonts');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final client = HttpClient();

  for (final family in fonts.keys) {
    print('Processing $family...');
    try {
      final req = await client.getUrl(Uri.parse('https://gwfh.mranv.com/api/fonts/$family'));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body);
      
      for (final variant in data['variants']) {
        final weight = variant['fontWeight'].toString();
        final style = variant['fontStyle'];
        final fontKey = style == 'italic' ? '${weight}i' : weight;
        
        if (fonts[family]!.containsKey(fontKey)) {
          final ttfUrl = variant['ttf'];
          final filename = fonts[family]![fontKey];
          final dest = '${dir.path}/$filename';
          
          print('Downloading $dest from $ttfUrl');
          final dlReq = await client.getUrl(Uri.parse(ttfUrl));
          final dlRes = await dlReq.close();
          final file = File(dest);
          await dlRes.pipe(file.openWrite());
          print('Saved $dest');
        }
      }
    } catch (e) {
      print('Error with $family: $e');
    }
  }
  client.close();
}
