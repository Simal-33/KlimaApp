import 'dart:io';

const Map<String, String> _mime = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.woff2': 'font/woff2',
};

void main(List<String> args) async {
  final port = args.isNotEmpty ? int.parse(args[0]) : 8765;
  final root = Directory('build/web');
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('Serving ${root.path} on http://127.0.0.1:$port');
  await for (final request in server) {
    var path = request.uri.path == '/' ? '/index.html' : request.uri.path;
    var file = File('${root.path}$path');
    if (!await file.exists()) {
      file = File('${root.path}/index.html');
    }
    final ext = path.contains('.') ? path.substring(path.lastIndexOf('.')) : '';
    request.response.headers.contentType = ContentType.parse(_mime[ext] ?? 'application/octet-stream');
    if (await file.exists()) {
      await request.response.addStream(file.openRead());
    } else {
      request.response.statusCode = HttpStatus.notFound;
    }
    await request.response.close();
  }
}
