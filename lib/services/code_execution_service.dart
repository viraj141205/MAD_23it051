import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firestore_database.dart';

class CodeExecutionResult {
  final String stdout;
  final String stderr;
  final String? compileOutput;
  final int exitCode;
  final bool isMock;

  CodeExecutionResult({
    required this.stdout,
    required this.stderr,
    this.compileOutput,
    required this.exitCode,
    this.isMock = false,
  });

  bool get hasErrors => stderr.isNotEmpty || (compileOutput != null && compileOutput!.isNotEmpty);
}

class CodeExecutionService {
  static const String _defaultBaseUrl = 'https://emkc.org/api/v2/piston/execute';
  static const String _judge0BaseUrl = 'https://ce.judge0.com/submissions?base64_encoded=false&wait=true';

  static final Map<String, String> _pistonLanguageMap = {
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

  // Language IDs for ce.judge0.com
  static final Map<String, int> _judge0LanguageMap = {
    'Java': 62,
    'C++': 54, // GCC 9.2.0
    'Python': 71, // 3.8.1
    'JavaScript': 63, // Node.js 12.14.0
    'C': 50, // GCC 9.2.0
    'Ruby': 72,
    'Go': 60,
    'Rust': 73,
    'PHP': 68,
    'C#': 51,
    'TypeScript': 74,
  };

  static String? getPistonLanguage(String language) {
    return _pistonLanguageMap[language];
  }

  static int? getJudge0LanguageId(String language) {
    return _judge0LanguageMap[language];
  }

  static Future<CodeExecutionResult?> executeCode(String code, String language) async {
    // 1. Try User-configured API (if any)
    try {
      final settings = await FirestoreDatabase.getUserSettings();
      if (settings != null && settings['pistonUrl'] != null && settings['pistonUrl'] != _defaultBaseUrl) {
         return await _executeWithPiston(code, language, settings['pistonUrl'], settings['pistonKey']);
      }
    } catch (e) {
      print('Error fetching settings: $e');
    }

    // 2. Try Judge0 (Primary for public)
    final judge0Id = getJudge0LanguageId(language);
    if (judge0Id != null) {
      try {
        final result = await _executeWithJudge0(code, judge0Id);
        if (result != null && !result.stderr.contains('403') && !result.stderr.contains('401')) {
           return result;
        }
      } catch (e) {
        print('Judge0 failed: $e');
      }
    }

    // 3. Try Piston (Legacy Fallback - will likely 401)
    return await _executeWithPiston(code, language, _defaultBaseUrl, null);
  }

  static Future<CodeExecutionResult?> _executeWithPiston(String code, String language, String apiUrl, String? apiKey) async {
    final pistonLang = getPistonLanguage(language);
    if (pistonLang == null) return null;

    try {
      final headers = {'Content-Type': 'application/json'};
      if (apiKey != null && apiKey.isNotEmpty) {
        headers['Authorization'] = apiKey;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode({
          'language': pistonLang,
          'version': '*',
          'files': [
            {'content': code}
          ],
        }),
      ).timeout(const Duration(seconds: 10));

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
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return _runMockExecution(code, language, 'API ERROR (${response.statusCode})');
      } else {
        return CodeExecutionResult(
          stdout: '',
          stderr: 'API ERROR (${response.statusCode}): ${response.body}',
          exitCode: response.statusCode,
        );
      }
    } catch (e) {
      return _runMockExecution(code, language, 'Connection Error: $e');
    }
  }

  static Future<CodeExecutionResult?> _executeWithJudge0(String code, int languageId) async {
    try {
      final response = await http.post(
        Uri.parse(_judge0BaseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'source_code': code,
          'language_id': languageId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CodeExecutionResult(
          stdout: data['stdout'] ?? '',
          stderr: data['stderr'] ?? '',
          compileOutput: data['compile_output'],
          exitCode: (data['status']?['id'] == 3) ? 0 : 1,
        );
      }
    } catch (e) {
       print('Judge0 internal error: $e');
    }
    return null;
  }

  static CodeExecutionResult _runMockExecution(String code, String language, String originalError) {
    String stdout = '';
    String stderr = '';
    
    final normalizedCode = code.toLowerCase().trim();
    
    if (normalizedCode.contains('hello world')) {
      stdout = 'Hello World!\n';
    } else if (normalizedCode.contains('print(') || normalizedCode.contains('console.log(') || normalizedCode.contains('cout <<')) {
      stdout = 'Execution successful (mock output for demo purposes).\n';
    } else {
      stderr = '$originalError\n\n(No simulated output found for this snippet. Public APIs are restricted; please configure a private instance in Settings.)';
    }

    return CodeExecutionResult(
      stdout: stdout,
      stderr: stderr,
      exitCode: stderr.isEmpty ? 0 : -1,
      isMock: true,
    );
  }
}
