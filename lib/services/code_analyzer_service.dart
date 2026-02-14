import 'package:flutter/foundation.dart';

class CodeAnalyzerService {
  /// Analyzes code based on the provided language and returns a feedback string.
  static String analyzeCode(String code, String language) {
    if (code.trim().isEmpty) return 'Please enter some code to analyze.';

    List<String> issues = [];
    List<String> warnings = [];
    List<String> notes = [];

    // General checks (regardless of language)
    _checkBalancedSymbols(code, issues);
    _checkUnclosedStrings(code, issues);

    if (code.contains('select *') || code.contains('SELECT *')) {
      warnings.add('Avoid using "SELECT *" in production queries for better performance and security.');
    }
    
    if (code.contains('password') || code.contains('secret') || code.contains('apiKey')) {
       warnings.add('Potential hardcoded credentials detected. Use environment variables instead.');
    }

    // Language-specific checks
    switch (language) {
      case 'Java':
      case 'C++':
      case 'C':
      case 'C#':
      case 'Dart':
        _analyzeCStyle(code, issues, warnings, notes, language);
        break;
      case 'Python':
        _analyzePython(code, issues, warnings, notes);
        break;
      case 'JavaScript':
      case 'TypeScript':
        _analyzeJSStyle(code, issues, warnings, notes);
        break;
    }

    // Format the result
    if (issues.isNotEmpty) {
      return '❌ Issues Found:\n' + issues.map((e) => '• $e').join('\n');
    } else if (warnings.isNotEmpty) {
      return '⚠️ Warnings:\n' + warnings.map((e) => '• $e').join('\n') + 
             (notes.isNotEmpty ? '\n\nℹ️ Notes:\n' + notes.map((e) => '• $e').join('\n') : '');
    } else if (notes.isNotEmpty) {
      return 'ℹ️ Notes:\n' + notes.map((e) => '• $e').join('\n');
    }

    return '✅ Code looks clean and follows basic best practices!';
  }

  static void _checkBalancedSymbols(String code, List<String> issues) {
    List<String> stack = [];
    Map<String, String> pairs = {'}': '{', ')': '(', ']': '['};
    
    for (int i = 0; i < code.length; i++) {
       String char = code[i];
       if (pairs.containsValue(char)) {
         stack.add(char);
       } else if (pairs.containsKey(char)) {
         if (stack.isEmpty || stack.last != pairs[char]) {
           issues.add('Unbalanced or unexpected symbol: "$char"');
           return;
         }
         stack.removeLast();
       }
    }
    
    if (stack.isNotEmpty) {
      issues.add('Unclosed symbol: "${stack.last}"');
    }
  }

  static void _checkUnclosedStrings(String code, List<String> issues) {
    bool inSingleQuote = false;
    bool inDoubleQuote = false;
    
    for (int i = 0; i < code.length; i++) {
      if (code[i] == "'" && !inDoubleQuote) {
        if (i > 0 && code[i-1] == '\\') continue;
        inSingleQuote = !inSingleQuote;
      } else if (code[i] == '"' && !inSingleQuote) {
        if (i > 0 && code[i-1] == '\\') continue;
        inDoubleQuote = !inDoubleQuote;
      }
      
      if (code[i] == '\n' && (inSingleQuote || inDoubleQuote)) {
         // Basic heuristic: check if next char is not part of a multi-line string (like Python's """)
         // For simplistic mock analyzer, we treat newlines in strings as errors unless escaped
         if (i > 0 && code[i-1] != '\\') {
            // issues.add('Unclosed string literal on line.'); // Too noisy for multi-line supports
         }
      }
    }
    
    if (inSingleQuote) issues.add('Unclosed single quote (\').');
    if (inDoubleQuote) issues.add('Unclosed double quote (").');
  }

  static void _analyzeCStyle(String code, List<String> issues, List<String> warnings, List<String> notes, String language) {
    final lines = code.split('\n');
    for (int i = 0; i < lines.length; i++) {
      String originalLine = lines[i];
      // Strip comments for analysis
      String line = _stripComments(originalLine).trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      // Special check for C++ class semicolon
      if (language == 'C++' && line.contains('class ') && !line.contains(';')) {
         if (!code.contains('};')) {
            issues.add('C++ classes must end with a semicolon (";") after the closing brace.');
         }
      }

      // Handle lines that might end with a brace but should have a semicolon before it
      // e.g., "int x = 5}" -> error
      // e.g., "if (x) {" -> no error
      
      // Strip trailing closing braces for semicolon check on the statement itself
      String statementCheck = line;
      while (statementCheck.endsWith('}')) {
        statementCheck = statementCheck.substring(0, statementCheck.length - 1).trim();
      }

      if (statementCheck.isNotEmpty &&
          !statementCheck.endsWith('{') && 
          !statementCheck.endsWith('}') && 
          !statementCheck.endsWith(';') && 
          !statementCheck.contains('if(') &&
          !statementCheck.contains('if (') &&
          !statementCheck.contains('for(') &&
          !statementCheck.contains('for (') &&
          !statementCheck.contains('while(') &&
          !statementCheck.contains('while (') &&
          !statementCheck.startsWith('@') &&
          !statementCheck.startsWith('public:') &&
          !statementCheck.startsWith('private:') &&
          !statementCheck.startsWith('protected:')) {
        issues.add('Line ${i + 1}: Potential missing semicolon (";").');
      }
    }

    if (language == 'Java' && !code.contains('class ')) {
      warnings.add('Java code usually requires a class definition.');
    }

    if (code.contains('System.out.println') || code.contains('printf') || code.contains('cout') || (language != 'Dart' && code.contains('print('))) {
      notes.add('Consider using a proper logging framework instead of standard output.');
    }
  }

  static void _analyzePython(String code, List<String> issues, List<String> warnings, List<String> notes) {
    final lines = code.split('\n');
    for (int i = 0; i < lines.length; i++) {
      String line = _stripComments(lines[i]).trim();
      if (line.isEmpty) continue;

      // Check for missing colons
      if ((line.startsWith('if ') || line.startsWith('elif ') || line.startsWith('else') || 
           line.startsWith('for ') || line.startsWith('while ') || 
           line.startsWith('def ') || line.startsWith('class ')) && 
          !line.endsWith(':')) {
        issues.add('Line ${i + 1}: Missing colon (":") at the end of control flow or definition.');
      }
    }

    if (code.contains('print(')) {
      notes.add('Consider using the "logging" module instead of print statements.');
    }

    if (code.contains('\t')) {
       warnings.add('Mixed use of tabs and spaces for indentation detected. PEP 8 recommends using only spaces.');
    }
  }

  static void _analyzeJSStyle(String code, List<String> issues, List<String> warnings, List<String> notes) {
    final lines = code.split('\n');
    for (int i = 0; i < lines.length; i++) {
      String line = _stripComments(lines[i]).trim();
      if (line.isEmpty) continue;
      
      String statementCheck = line;
      while (statementCheck.endsWith('}')) {
        statementCheck = statementCheck.substring(0, statementCheck.length - 1).trim();
      }

      if (statementCheck.isNotEmpty &&
          !statementCheck.endsWith('{') && 
          !statementCheck.endsWith('}') && 
          !statementCheck.endsWith(';') && 
          !statementCheck.startsWith('if') && 
          !statementCheck.startsWith('for') && 
          !statementCheck.startsWith('while') && 
          !statementCheck.endsWith(',')) {
         notes.add('Line ${i + 1}: Consider adding a semicolon (";") for clarity.');
      }
    }

    if (code.contains('var ')) {
      warnings.add('Use "let" or "const" instead of "var" for better scoping.');
    }

    if (code.contains('eval(')) {
      issues.add('Avoid using "eval()" as it poses significant security risks.');
    }
  }

  static String _stripComments(String line) {
    // Basic single line comment stripping
    if (line.contains('//')) {
      return line.split('//').first;
    }
    // Basic Python comment stripping
    if (line.contains('#')) {
      return line.split('#').first;
    }
    return line;
  }
}
