import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result of a Judge0 code execution.
class CodeExecutionResult {
  final String stdout;
  final String stderr;
  final String? compileOutput;
  final int exitCode;
  final String statusDescription;

  const CodeExecutionResult({
    required this.stdout,
    required this.stderr,
    this.compileOutput,
    required this.exitCode,
    this.statusDescription = '',
  });

  bool get hasErrors =>
      stderr.isNotEmpty ||
      (compileOutput != null && compileOutput!.isNotEmpty);

  bool get isSuccess => exitCode == 0 && !hasErrors;
}

/// Executes code exclusively via the Judge0 Community Edition public API.
class CodeExecutionService {
  // Judge0 CE – submissions endpoint (wait=true → synchronous result)
  static const String _judge0Url =
      'https://ce.judge0.com/submissions?base64_encoded=false&wait=true';

  /// Language IDs for ce.judge0.com
  /// Full list: https://ce.judge0.com/languages
  static const Map<String, int> _languageIds = {
    'C': 50,          // GCC 9.2.0
    'C++': 54,        // GCC 9.2.0
    'C#': 51,         // Mono 6.6.0
    'Java': 62,       // OpenJDK 13.0.1
    'Kotlin': 78,     // 1.3.70
    'Python': 71,     // CPython 3.8.1
    'JavaScript': 63, // Node.js 12.14.0
    'TypeScript': 74, // 3.7.4
    'Go': 60,         // 1.13.5
    'Rust': 73,       // 1.40.0
    'Ruby': 72,       // 2.7.0
    'PHP': 68,        // 7.4.1
    'Swift': 83,      // 5.2.3
    'Dart': 90,       // 2.19.2 (if available on the instance)
  };

  /// Returns the Judge0 language ID for [language], or null if unsupported.
  static int? getLanguageId(String language) => _languageIds[language];

  /// Returns the list of languages supported by Judge0.
  static List<String> get supportedLanguages =>
      _languageIds.keys.toList()..sort();

  /// Execute [code] written in [language] using Judge0.
  ///
  /// Returns a [CodeExecutionResult] describing stdout/stderr/compile output.
  /// Throws an exception if the language is unsupported or the HTTP call fails.
  static Future<CodeExecutionResult> executeCode(
      String code, String language) async {
    final langId = getLanguageId(language);
    if (langId == null) {
      throw UnsupportedError(
          '$language is not supported by Judge0 in this app.');
    }

    final response = await http
        .post(
          Uri.parse(_judge0Url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'source_code': code,
            'language_id': langId,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseResponse(jsonDecode(response.body));
    }

    throw Exception(
        'Judge0 returned HTTP ${response.statusCode}: ${response.body}');
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  static CodeExecutionResult _parseResponse(Map<String, dynamic> data) {
    final statusId = data['status']?['id'] as int? ?? -1;
    final statusDesc =
        data['status']?['description'] as String? ?? 'Unknown';

    // Status 3 = Accepted (successful run)
    final isAccepted = statusId == 3;

    return CodeExecutionResult(
      stdout: (data['stdout'] ?? '').toString().trim(),
      stderr: (data['stderr'] ?? '').toString().trim(),
      compileOutput: (data['compile_output'] ?? '').toString().trim().isEmpty
          ? null
          : data['compile_output'].toString().trim(),
      exitCode: isAccepted ? 0 : 1,
      statusDescription: statusDesc,
    );
  }
}
