import 'dart:convert';
import 'package:http/http.dart' as http;

class CodeExecutionResult {
  final String stdout;
  final String stderr;
  final String? compileOutput;
  final int exitCode;

  CodeExecutionResult({
    required this.stdout,
    required this.stderr,
    this.compileOutput,
    required this.exitCode,
  });

  bool get hasErrors => stderr.isNotEmpty || (compileOutput != null && compileOutput!.isNotEmpty);
}

class CodeExecutionService {
  static const String _baseUrl = 'https://emkc.org/api/v2/piston/execute';

  static final Map<String, String> _languageMap = {
    'Java': 'java',
    'C++': 'cpp',
    'Python': 'python',
    'JavaScript': 'javascript',
    'Dart': 'dart',
    'Go': 'go',
    'Rust': 'rust',
    'Swift': 'swift',
    'Kotlin': 'kotlin',
    'PHP': 'php',
    'C#': 'csharp',
    'Ruby': 'ruby',
    'C': 'c',
    'TypeScript': 'typescript',
  };

  static String? getPistonLanguage(String language) {
    return _languageMap[language];
  }

  static Future<CodeExecutionResult?> executeCode(String code, String language) async {
    final pistonLang = getPistonLanguage(language);
    if (pistonLang == null) return null;

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'language': pistonLang,
          'version': '*',
          'files': [
            {'content': code}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final run = data['run'];
        final compile = data['compile'];

        return CodeExecutionResult(
          stdout: run['stdout'] ?? '',
          stderr: run['stderr'] ?? '',
          compileOutput: compile != null ? (compile['stdout'] ?? '') + (compile['stderr'] ?? '') : null,
          exitCode: run['code'] ?? 0,
        );
      }
    } catch (e) {
      print('Error executing code: $e');
    }
    return null;
  }
}
