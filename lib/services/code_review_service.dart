import 'package:google_generative_ai/google_generative_ai.dart';
import 'firestore_database.dart';

class CodeReviewService {
  /// Provides qualitative feedback and review for the given code and language.
  /// Attempts to use Gemini AI if an API key is available, otherwise falls back to heuristics.
  static Future<Map<String, List<String>>> reviewCode(String code, String language) async {
    if (code.trim().isEmpty) {
      return {
        'critical': ['Please enter some code for review.'],
        'suggestions': [],
        'security': [],
        'best_practices': []
      };
    }

    // Try Gemini AI first
    final settings = await FirestoreDatabase.getUserSettings();
    final apiKey = settings?['geminiKey'];

    if (apiKey != null && apiKey.toString().isNotEmpty) {
      try {
        return await _reviewWithGemini(code, language, apiKey.toString());
      } catch (e) {
        print('Gemini AI Error: $e');
        // Fallback to heuristics on error
      }
    }

    // Heuristics Fallback
    Map<String, List<String>> review = {
      'critical': [],
      'suggestions': [],
      'security': [],
      'best_practices': []
    };

    _generalReviewHeuristics(code, review);

    switch (language) {
      case 'Python':
        _reviewPythonHeuristics(code, review);
        break;
      case 'JavaScript':
      case 'TypeScript':
        _reviewJavaScriptHeuristics(code, review);
        break;
      case 'Java':
      case 'Dart':
      case 'C++':
      case 'C#':
        _reviewCStyleHeuristics(code, review, language);
        break;
      default:
        review['suggestions']!.add('Detailed review is not yet available for $language, but general checks were applied.');
    }

    return review;
  }

  static Future<Map<String, List<String>>> _reviewWithGemini(String code, String language, String apiKey) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    
    final prompt = '''
    As an expert senior software engineer, review the following $language code snippet.
    Provide your review in a structured format with 4 categories:
    1. Critical Issues (Bugs, syntax errors, or major flaws)
    2. Security (Vulnerabilities, hardcoded secrets, unsafe functions)
    3. Best Practices (Readability, naming conventions, architectural improvements)
    4. Suggestions (Minor optimizations, alternative approaches)

    Format each category with a header starting with "CATEGORY:" followed by the name, then list each point with "•".
    Keep descriptions concise but professional.

    CODE:
    $code
    ''';

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    
    return _parseGeminiResponse(response.text ?? '');
  }

  static Map<String, List<String>> _parseGeminiResponse(String text) {
    Map<String, List<String>> review = {
      'critical': [],
      'security': [],
      'best_practices': [],
      'suggestions': []
    };

    String currentCategory = '';
    final lines = text.split('\n');

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.toUpperCase().contains('CATEGORY:')) {
        if (trimmed.toUpperCase().contains('CRITICAL')) currentCategory = 'critical';
        else if (trimmed.toUpperCase().contains('SECURITY')) currentCategory = 'security';
        else if (trimmed.toUpperCase().contains('BEST PRACTICES')) currentCategory = 'best_practices';
        else if (trimmed.toUpperCase().contains('SUGGESTIONS')) currentCategory = 'suggestions';
      } else if (currentCategory.isNotEmpty && (trimmed.startsWith('•') || trimmed.startsWith('*') || trimmed.startsWith('-'))) {
        // Remove the bullet point prefix
        final cleanLine = trimmed.substring(1).trim();
        if (cleanLine.isNotEmpty) {
          review[currentCategory]!.add(cleanLine);
        }
      } else if (currentCategory.isNotEmpty && !trimmed.contains('CATEGORY:')) {
        // Handle lines that might not start with a bullet but are part of a point
        if (review[currentCategory]!.isNotEmpty) {
           final lastIdx = review[currentCategory]!.length - 1;
           review[currentCategory]![lastIdx] = '${review[currentCategory]![lastIdx]} $trimmed';
        } else {
           review[currentCategory]!.add(trimmed);
        }
      }
    }

    return review;
  }

  // --- Heuristics Fallback Methods ---

  static void _generalReviewHeuristics(String code, Map<String, List<String>> review) {
    if (code.length > 1000) {
      review['suggestions']!.add('Snippet is long. Consider breaking it down into smaller modules.');
    }

    if (code.contains('password') || code.contains('secret') || code.contains('apiKey')) {
      review['security']!.add('Potential hardcoded secrets detected.');
    }

    if (code.contains('select *') || code.contains('SELECT *')) {
      review['best_practices']!.add('Avoid "SELECT *"; specify columns explicitly.');
    }
  }

  static void _reviewPythonHeuristics(String code, Map<String, List<String>> review) {
    if (code.contains('import *')) {
      review['best_practices']!.add('Avoid wildcard imports (PEP 8).');
    }
    if (code.contains('except:')) {
      review['security']!.add('Avoid bare "except:" clauses.');
    }
  }

  static void _reviewJavaScriptHeuristics(String code, Map<String, List<String>> review) {
    if (code.contains('var ')) {
      review['best_practices']!.add('Use "let" or "const" instead of "var".');
    }
    if (code.contains('eval(')) {
      review['security']!.add('Avoid "eval()" due to security risks.');
    }
  }

  static void _reviewCStyleHeuristics(String code, Map<String, List<String>> review, String language) {
    int maxNesting = 0;
    int currentNesting = 0;
    for (int i = 0; i < code.length; i++) {
      if (code[i] == '{') {
        currentNesting++;
        if (currentNesting > maxNesting) maxNesting = currentNesting;
      } else if (code[i] == '}') {
        currentNesting--;
      }
    }
    if (maxNesting > 3) {
      review['suggestions']!.add('High nesting detected (level $maxNesting). Consider refactoring.');
    }
  }
}
