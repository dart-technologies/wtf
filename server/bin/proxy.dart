import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:http/http.dart' as http;

/// Thin proxy that forwards requests to the Anthropic API.
/// Solves CORS for Flutter web — both panels hit localhost:8080.
///
/// Usage:
///   cd server && dart run bin/proxy.dart
///
/// Reads CLAUDE_API_KEY from environment or ../.env file.
void main() async {
  final apiKey = Platform.environment['CLAUDE_API_KEY'] ?? _readEnvFile();

  if (apiKey.isEmpty) {
    stderr.writeln('ERROR: CLAUDE_API_KEY not set.');
    stderr.writeln('Either export it or add it to ../.env');
    exit(1);
  }

  print('API key loaded (${apiKey.substring(0, 10)}...)');

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler((Request request) => _handleRequest(request, apiKey));

  final server = await io.serve(handler, 'localhost', 8080);
  print('Proxy running at http://${server.address.host}:${server.port}');
}

Future<Response> _handleRequest(Request request, String apiKey) async {
  // Only proxy POST to /v1/messages
  if (request.method != 'POST') {
    return Response.ok(jsonEncode({'status': 'WTF proxy running'}),
        headers: {'content-type': 'application/json'});
  }

  try {
    final body = await request.readAsString();

    final resp = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: body,
    );

    return Response(resp.statusCode,
        body: resp.body,
        headers: {'content-type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'});
  }
}

/// Read CLAUDE_API_KEY from the project root .env file.
String _readEnvFile() {
  try {
    final envFile = File('../.env');
    if (!envFile.existsSync()) return '';
    for (final line in envFile.readAsLinesSync()) {
      if (line.startsWith('CLAUDE_API_KEY=')) {
        return line.substring('CLAUDE_API_KEY='.length).trim();
      }
    }
  } catch (_) {}
  return '';
}
