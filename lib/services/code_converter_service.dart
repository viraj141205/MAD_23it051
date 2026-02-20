import 'package:google_generative_ai/google_generative_ai.dart';

class CodeConverterService {
  static const String _geminiKey = 'AIzaSyDrbfPBOK3ZAAZn2pUHaCx5nx20R5dBbEU';

  /// Converts [code] from [fromLang] to [toLang].
  /// Tries Gemini first; falls back to local transpiler on quota failure.
  static Future<String> convertCode(
      String code, String fromLang, String toLang) async {
    if (code.trim().isEmpty) return '// No code to convert.';
    if (fromLang == toLang) return code;

    // ── 1. Try Gemini ────────────────────────────────────────────────────────
    try {
      final model =
          GenerativeModel(model: 'gemini-2.0-flash', apiKey: _geminiKey);
      final response = await model
          .generateContent([Content.text(_buildPrompt(code, fromLang, toLang))])
          .timeout(const Duration(seconds: 30));
      final text = response.text ?? '';
      if (text.trim().isNotEmpty) return _stripFences(text.trim());
    } catch (_) {
      // Gemini unavailable → fall through to local transpiler
    }

    // ── 2. Local transpiler ──────────────────────────────────────────────────
    return _LocalTranspiler(code, fromLang, toLang).transpile();
  }

  // ─── Prompt ─────────────────────────────────────────────────────────────────

  static String _buildPrompt(String code, String from, String to) {
    return 'You are an expert software engineer.\n'
        'Task: Convert the $from code below into equivalent $to code.\n'
        'RULES: Output ONLY the converted $to code. No explanations. '
        'No markdown fences.\n\n'
        '$from CODE:\n$code';
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static String _stripFences(String text) {
    final fence = RegExp(r'^```[a-zA-Z+#]*\n?([\s\S]*?)```\s*$');
    final match = fence.firstMatch(text);
    return match != null ? (match.group(1)?.trim() ?? text) : text;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Local Transpiler — handles Java, Python, C++, C, JavaScript, Dart as source
// ═══════════════════════════════════════════════════════════════════════════════

class _LocalTranspiler {
  final String source;
  final String from;
  final String to;

  _LocalTranspiler(this.source, this.from, this.to);

  String get _fromKey => from.toLowerCase();
  String get _toKey => to.toLowerCase();

  String transpile() {
    if (_fromKey.contains('java')) return _fromJava();
    if (_fromKey.contains('python')) return _fromPython();
    if (_fromKey.contains('c++') || _fromKey == 'cpp') return _fromCpp();
    if (_fromKey == 'c') return _fromC();
    if (_fromKey.contains('javascript') || _fromKey == 'js') return _fromJs();
    if (_fromKey.contains('dart')) return _fromDart();
    if (_fromKey.contains('kotlin')) return _fromKotlin();
    return _unsupported();
  }

  // ─── From Java ─────────────────────────────────────────────────────────────

  String _fromJava() {
    final lines = source.split('\n');
    final body = <String>[];


    for (final raw in lines) {
      final line = raw.trimRight();
      final t = line.trim();

      // Skip blank lines inside class/main wrapper — we re-add them
      if (t.isEmpty) { body.add(''); continue; }
      // Skip class declaration
      if (RegExp(r'^public\s+class\s+\w+\s*\{').hasMatch(t)) {
        continue;
      }
      // Skip main method declaration line — handle below
      if (RegExp(r'public\s+static\s+void\s+main').hasMatch(t)) {
        continue;
      }
      // Skip import statements
      if (t.startsWith('import ')) continue;
      // Skip lone closing braces of class/main (heuristic: no other content)
      if (t == '}') {
        continue;
      }

      body.add(_convertJavaLine(t));
    }

    // Remove leading/trailing blank lines from body
    while (body.isNotEmpty && body.first.trim().isEmpty) body.removeAt(0);
    while (body.isNotEmpty && body.last.trim().isEmpty) body.removeLast();

    return _wrapInMain(body, _toKey);
  }

  String _convertJavaLine(String t) {
    // ── Comments ──
    if (t.startsWith('//')) return _commentFor(t.substring(2).trim(), _toKey);
    if (t.startsWith('/*') || t.startsWith('*')) {
      return _commentFor(t.replaceAll(RegExp(r'^/?\*+/?'), '').trim(), _toKey);
    }

    // ── Variable declarations with assignment ──
    // int x = expr; / double x = expr; etc.
    final varDecl = RegExp(
        r'^(int|long|double|float|short|byte|boolean|char|String|var)\s+(\w+)\s*=\s*(.+?);?$');
    final vMatch = varDecl.firstMatch(t);
    if (vMatch != null) {
      final jType = vMatch.group(1)!;
      final name = vMatch.group(2)!;
      final expr = _convertExpr(vMatch.group(3)!, _toKey);
      return _varDecl(jType, name, expr, _toKey);
    }

    // ── Variable declaration without assignment ──
    final varOnly =
        RegExp(r'^(int|long|double|float|short|byte|boolean|char|String)\s+(\w+);?$');
    final voMatch = varOnly.firstMatch(t);
    if (voMatch != null) {
      final jType = voMatch.group(1)!;
      final name = voMatch.group(2)!;
      return _varDeclOnly(jType, name, _toKey);
    }

    // ── Assignment (no type) ──
    final assign = RegExp(r'^(\w+)\s*([\+\-\*\/\%]?=)\s*(.+?);?$');
    final aMatch = assign.firstMatch(t);
    if (aMatch != null && !t.startsWith('if') && !t.startsWith('while')) {
      final name = aMatch.group(1)!;
      final op = aMatch.group(2)!;
      final expr = _convertExpr(aMatch.group(3)!, _toKey);
      return _assignment(name, op, expr, _toKey);
    }

    // ── System.out.println ──
    final sysout = RegExp(r'System\.out\.println\s*\((.+?)\);?$');
    final soMatch = sysout.firstMatch(t);
    if (soMatch != null) {
      final arg = _convertExpr(soMatch.group(1)!, _toKey);
      return _printLn(arg, _toKey);
    }

    // ── System.out.print (no newline) ──
    final sysoprint = RegExp(r'System\.out\.print\s*\((.+?)\);?$');
    final sopMatch = sysoprint.firstMatch(t);
    if (sopMatch != null) {
      final arg = _convertExpr(sopMatch.group(1)!, _toKey);
      return _print(arg, _toKey);
    }

    // ── for loop: for (int i = start; i < end; i++) ──
    final forLoop =
        RegExp(r'^for\s*\(\s*(?:int|long)?\s*(\w+)\s*=\s*(.+?);\s*\1\s*(<|<=|>|>=|!=)\s*(.+?);\s*\1(\+\+|--|[+\-]=.+?)\s*\)(.*)$');
    final fMatch = forLoop.firstMatch(t);
    if (fMatch != null) {
      final v = fMatch.group(1)!;
      final start = _convertExpr(fMatch.group(2)!, _toKey);
      final op = fMatch.group(3)!;
      final end = _convertExpr(fMatch.group(4)!, _toKey);
      final step = fMatch.group(5)!;
      final rest = fMatch.group(6)!.trim();
      final body = rest == '{' ? '' : (rest.isNotEmpty ? _convertJavaLine(rest) : '');
      return _forLoop(v, start, op, end, step, body, _toKey);
    }

    // ── while loop ──
    final whileLoop = RegExp(r'^while\s*\((.+?)\)\s*(\{)?$');
    final wMatch = whileLoop.firstMatch(t);
    if (wMatch != null) {
      final cond = _convertExpr(wMatch.group(1)!, _toKey);
      return _whileLoop(cond, _toKey);
    }

    // ── if statement ──
    final ifStmt = RegExp(r'^if\s*\((.+?)\)\s*(\{)?$');
    final ifMatch = ifStmt.firstMatch(t);
    if (ifMatch != null) {
      final cond = _convertExpr(ifMatch.group(1)!, _toKey);
      return _ifStmt(cond, _toKey);
    }

    // ── else if ──
    final elseIf = RegExp(r'^else\s+if\s*\((.+?)\)\s*(\{)?$');
    final eiMatch = elseIf.firstMatch(t);
    if (eiMatch != null) {
      final cond = _convertExpr(eiMatch.group(1)!, _toKey);
      return _elseIfStmt(cond, _toKey);
    }

    // ── else ──
    if (t == 'else' || t == 'else {') return _elseStmt(_toKey);

    // ── return ──
    final ret = RegExp(r'^return\s+(.+?);?$');
    final rMatch = ret.firstMatch(t);
    if (rMatch != null) {
      final val = _convertExpr(rMatch.group(1)!, _toKey);
      return _returnStmt(val, _toKey);
    }

    // ── Opening/closing braces → converted to colons or removed ──
    if (t == '{') return _openBrace(_toKey);
    if (t == '}') return _closeBrace(_toKey);

    // ── Scanner input (simplified) ──
    if (t.contains('Scanner') || t.contains('nextInt') ||
        t.contains('nextDouble') || t.contains('nextLine')) {
      return _commentFor('// [input] $t', _toKey);
    }

    // Passthrough (expressions, etc.)
    return _convertExpr(t.replaceAll(';', ''), _toKey) +
        (_needsSemicolon(_toKey) ? ';' : '');
  }

  // ─── From Python ───────────────────────────────────────────────────────────

  String _fromPython() {
    final lines = source.split('\n');
    final body = <String>[];

    for (final raw in lines) {
      final t = raw.trim();
      if (t.isEmpty) { body.add(''); continue; }
      if (t.startsWith('#')) {
        body.add(_commentFor(t.substring(1).trim(), _toKey));
        continue;
      }

      // print("...") or print(expr)
      final printQ = RegExp(r"^print\s*\(\s*'([^']*)'\s*\)$");
      final printD = RegExp(r'^print\s*\(\s*"([^"]*)"\s*\)$');
      final printE = RegExp(r'^print\s*\((.+)\)$');
      final pqM = printQ.firstMatch(t);
      final pdM = printD.firstMatch(t);
      final peM = printE.firstMatch(t);
      if (pqM != null) {
        body.add(_printLn('"${pqM.group(1)}"', _toKey));
        continue;
      }
      if (pdM != null) {
        body.add(_printLn('"${pdM.group(1)}"', _toKey));
        continue;
      }
      if (peM != null) {
        body.add(_printLn(_convertExpr(peM.group(1)!, _toKey), _toKey));
        continue;
      }

      // x = expr (assignment)
      final assign = RegExp(r'^(\w+)\s*=\s*(.+)$');
      final aM = assign.firstMatch(t);
      if (aM != null && !t.startsWith('if') && !t.startsWith('while') &&
          !t.startsWith('for') && !t.startsWith('def') &&
          !t.startsWith('return')) {
        final name = aM.group(1)!;
        final expr = _convertExpr(aM.group(2)!, _toKey);
        body.add(_pyVarDecl(name, expr, _toKey));
        continue;
      }

      // for i in range(n): or for i in range(start, end):
      final forRange = RegExp(r'^for\s+(\w+)\s+in\s+range\s*\((.+)\)\s*:$');
      final fM = forRange.firstMatch(t);
      if (fM != null) {
        final v = fM.group(1)!;
        final args = fM.group(2)!.split(',').map((s) => s.trim()).toList();
        final start = args.length > 1 ? _convertExpr(args[0], _toKey) : '0';
        final end = _convertExpr(args.length > 1 ? args[1] : args[0], _toKey);
        body.add(_forLoop(v, start, '<', end, '++', '', _toKey));
        continue;
      }

      // while condition:
      final whileStmt = RegExp(r'^while\s+(.+)\s*:$');
      final wM = whileStmt.firstMatch(t);
      if (wM != null) {
        body.add(_whileLoop(_convertExpr(wM.group(1)!, _toKey), _toKey));
        continue;
      }

      // if / elif / else
      final ifRe = RegExp(r'^if\s+(.+)\s*:$');
      final elifRe = RegExp(r'^elif\s+(.+)\s*:$');
      final iM = ifRe.firstMatch(t);
      final eiM = elifRe.firstMatch(t);
      if (iM != null) { body.add(_ifStmt(_convertExpr(iM.group(1)!, _toKey), _toKey)); continue; }
      if (eiM != null) { body.add(_elseIfStmt(_convertExpr(eiM.group(1)!, _toKey), _toKey)); continue; }
      if (t == 'else:') { body.add(_elseStmt(_toKey)); continue; }

      // return
      final retRe = RegExp(r'^return\s+(.+)$');
      final rM = retRe.firstMatch(t);
      if (rM != null) {
        body.add(_returnStmt(_convertExpr(rM.group(1)!, _toKey), _toKey));
        continue;
      }

      // def function(args):
      final defRe = RegExp(r'^def\s+(\w+)\s*\(([^)]*)\)\s*:$');
      final dM = defRe.firstMatch(t);
      if (dM != null) {
        body.add(_funcDef(dM.group(1)!, dM.group(2)!, _toKey));
        continue;
      }

      body.add(_convertExpr(t, _toKey) + (_needsSemicolon(_toKey) ? ';' : ''));
    }

    while (body.isNotEmpty && body.first.trim().isEmpty) body.removeAt(0);
    while (body.isNotEmpty && body.last.trim().isEmpty) body.removeLast();

    return _wrapInMain(body, _toKey);
  }

  // ─── From C++ ──────────────────────────────────────────────────────────────

  String _fromCpp() {
    // Reuse Java converter — C++ shares most syntax with Java for basic code
    return _convertCStyleToTarget(source, 'cpp');
  }

  // ─── From C ───────────────────────────────────────────────────────────────

  String _fromC() {
    return _convertCStyleToTarget(source, 'c');
  }

  // ─── From JavaScript ──────────────────────────────────────────────────────

  String _fromJs() {
    return _convertCStyleToTarget(source, 'js');
  }

  // ─── From Dart ────────────────────────────────────────────────────────────

  String _fromDart() {
    return _convertCStyleToTarget(source, 'dart');
  }

  // ─── From Kotlin ──────────────────────────────────────────────────────────

  String _fromKotlin() {
    final lines = source.split('\n');
    final body = <String>[];
    for (final raw in lines) {
      final t = raw.trim();
      if (t.isEmpty) { body.add(''); continue; }
      if (t.startsWith('//')) { body.add(_commentFor(t.substring(2).trim(), _toKey)); continue; }
      if (t.startsWith('fun main')) continue;
      if (t == '{' || t == '}') { body.add(_openBrace(_toKey)); continue; }

      final printRe = RegExp(r'^println\s*\((.+)\)$');
      final pM = printRe.firstMatch(t);
      if (pM != null) { body.add(_printLn(_convertExpr(pM.group(1)!, _toKey), _toKey)); continue; }

      final valRe = RegExp(r'^(?:val|var)\s+(\w+)(?::\s*\w+)?\s*=\s*(.+)$');
      final vM = valRe.firstMatch(t);
      if (vM != null) {
        body.add(_pyVarDecl(vM.group(1)!, _convertExpr(vM.group(2)!, _toKey), _toKey));
        continue;
      }

      body.add(_convertExpr(t.replaceAll(';', ''), _toKey) +
          (_needsSemicolon(_toKey) ? ';' : ''));
    }
    while (body.isNotEmpty && body.first.trim().isEmpty) body.removeAt(0);
    while (body.isNotEmpty && body.last.trim().isEmpty) body.removeLast();
    return _wrapInMain(body, _toKey);
  }

  // ─── C-style generic converter ────────────────────────────────────────────

  String _convertCStyleToTarget(String code, String srcLang) {
    final lines = code.split('\n');
    final body = <String>[];

    for (final raw in lines) {
      final t = raw.trim();
      if (t.isEmpty) { body.add(''); continue; }

      // Skip preprocessor / includes
      if (t.startsWith('#')) continue;
      // Skip using namespace / package / import
      if (t.startsWith('using ') || t.startsWith('import ') ||
          t.startsWith('package ')) continue;

      // main function declaration
      if (RegExp(r'\bmain\s*\(').hasMatch(t) && t.contains('{')) continue;
      if (t == 'int main()' || t == 'int main(void)' || t == 'void main()') continue;

      if (t == '{') { body.add(_openBrace(_toKey)); continue; }
      if (t == '}') { body.add(_closeBrace(_toKey)); continue; }
      if (t == 'return 0;' || t == 'return 0') continue; // C/C++ main return

      if (t.startsWith('//')) { body.add(_commentFor(t.substring(2).trim(), _toKey)); continue; }

      // cout << expr << endl;
      final coutRe = RegExp(r'^(?:std::)?cout\s*<<\s*(.+?)(?:\s*<<\s*(?:std::)?endl)?\s*;?$');
      final cM = coutRe.firstMatch(t);
      if (cM != null) {
        final arg = _convertExpr(cM.group(1)!.trim(), _toKey);
        body.add(_printLn(arg, _toKey));
        continue;
      }

      // printf
      final printfRe = RegExp(r'^printf\s*\(\s*"([^"]*)"\s*(?:,\s*(.+?))?\s*\)\s*;?$');
      final pfM = printfRe.firstMatch(t);
      if (pfM != null) {
        final fmt = pfM.group(1)!.replaceAll(r'\n', '');
        final args = pfM.group(2);
        if (args != null && args.trim().isNotEmpty) {
          body.add(_printLn('"$fmt" + " " + $args', _toKey));
        } else {
          body.add(_printLn('"$fmt"', _toKey));
        }
        continue;
      }

      // console.log (JavaScript source)
      final consoleRe = RegExp(r'^console\.log\s*\((.+)\)\s*;?$');
      final conM = consoleRe.firstMatch(t);
      if (conM != null) {
        body.add(_printLn(_convertExpr(conM.group(1)!, _toKey), _toKey));
        continue;
      }

      // println! Rust
      final printlnRe = RegExp(r'^println!\s*\(\s*"([^"]*)"\s*\)\s*;?$');
      final plM = printlnRe.firstMatch(t);
      if (plM != null) {
        body.add(_printLn('"${plM.group(1)}"', _toKey));
        continue;
      }

      // Variable declarations
      final varRe = RegExp(
          r'^(?:int|long|double|float|bool|boolean|char|auto|var|let|const|String|string|std::string)\s+(\w+)\s*=\s*(.+?);?$');
      final vM = varRe.firstMatch(t);
      if (vM != null) {
        final name = vM.group(1)!;
        final expr = _convertExpr(vM.group(2)!, _toKey);
        // Guess type from value
        final jType = _guessType(vM.group(2)!);
        body.add(_varDecl(jType, name, expr, _toKey));
        continue;
      }

      // Assignment
      final assignRe = RegExp(r'^(\w+)\s*([\+\-\*\/\%]?=)\s*(.+?);?$');
      final aM = assignRe.firstMatch(t);
      if (aM != null && !t.startsWith('if') && !t.startsWith('while') &&
          !t.startsWith('for')) {
        body.add(_assignment(aM.group(1)!, aM.group(2)!,
            _convertExpr(aM.group(3)!, _toKey), _toKey));
        continue;
      }

      // for loop
      final forRe = RegExp(
          r'^for\s*\(\s*(?:\w+\s+)?(\w+)\s*=\s*(.+?);\s*\1\s*([<>!=]=?)\s*(.+?);\s*\1(\+\+|--|\s*[+\-]=\s*.+?)\s*\)\s*(\{)?$');
      final fM = forRe.firstMatch(t);
      if (fM != null) {
        body.add(_forLoop(fM.group(1)!, _convertExpr(fM.group(2)!, _toKey),
            fM.group(3)!, _convertExpr(fM.group(4)!, _toKey),
            fM.group(5)!, '', _toKey));
        continue;
      }

      // while
      final whileRe = RegExp(r'^while\s*\((.+?)\)\s*(\{)?$');
      final wM = whileRe.firstMatch(t);
      if (wM != null) {
        body.add(_whileLoop(_convertExpr(wM.group(1)!, _toKey), _toKey));
        continue;
      }

      // if / else if / else
      final ifRe = RegExp(r'^if\s*\((.+?)\)\s*(\{)?$');
      final elifRe = RegExp(r'^else\s+if\s*\((.+?)\)\s*(\{)?$');
      final iM = ifRe.firstMatch(t);
      final eiM = elifRe.firstMatch(t);
      if (iM != null) { body.add(_ifStmt(_convertExpr(iM.group(1)!, _toKey), _toKey)); continue; }
      if (eiM != null) { body.add(_elseIfStmt(_convertExpr(eiM.group(1)!, _toKey), _toKey)); continue; }
      if (t == 'else' || t == 'else {') { body.add(_elseStmt(_toKey)); continue; }

      // return
      final retRe = RegExp(r'^return\s+(.+?);?$');
      final rM = retRe.firstMatch(t);
      if (rM != null) {
        body.add(_returnStmt(_convertExpr(rM.group(1)!, _toKey), _toKey));
        continue;
      }

      body.add(_convertExpr(t.replaceAll(';', ''), _toKey) +
          (_needsSemicolon(_toKey) ? ';' : ''));
    }

    while (body.isNotEmpty && body.first.trim().isEmpty) body.removeAt(0);
    while (body.isNotEmpty && body.last.trim().isEmpty) body.removeLast();
    return _wrapInMain(body, _toKey);
  }

  // ─── Expression converter ─────────────────────────────────────────────────

  /// Converts expressions (Math functions, string concat, arithmetic).
  String _convertExpr(String expr, String t) {
    var e = expr.trim();

    // Math.pow(a, b)
    if (t == 'python') {
      e = e.replaceAllMapped(
          RegExp(r'Math\.pow\s*\(([^,]+),\s*([^)]+)\)'),
          (m) => '(${m.group(1)}) ** (${m.group(2)})');
    } else if (t == 'cpp' || t.contains('c++')) {
      e = e.replaceAllMapped(
          RegExp(r'Math\.pow\s*\(([^,]+),\s*([^)]+)\)'),
          (m) => 'pow(${m.group(1)}, ${m.group(2)})');
    } else if (t == 'c') {
      e = e.replaceAllMapped(
          RegExp(r'Math\.pow\s*\(([^,]+),\s*([^)]+)\)'),
          (m) => 'pow(${m.group(1)}, ${m.group(2)})');
    }

    // Math.sqrt(x)
    if (t == 'python') {
      e = e.replaceAllMapped(RegExp(r'Math\.sqrt\s*\(([^)]+)\)'),
          (m) => 'math.sqrt(${m.group(1)})');
    } else {
      e = e.replaceAllMapped(RegExp(r'Math\.sqrt\s*\(([^)]+)\)'),
          (m) => 'sqrt(${m.group(1)})');
    }

    // Math.abs(x)
    if (t == 'javascript' || t == 'js' || t == 'typescript' || t == 'ts') {
      e = e.replaceAllMapped(RegExp(r'Math\.abs\s*\(([^)]+)\)'),
          (m) => 'Math.abs(${m.group(1)})');
    } else {
      e = e.replaceAllMapped(RegExp(r'Math\.abs\s*\(([^)]+)\)'),
          (m) => 'abs(${m.group(1)})');
    }

    // Math.max / Math.min
    e = e.replaceAllMapped(RegExp(r'Math\.(max|min)\s*\(([^)]+)\)'),
        (m) => '${m.group(1) == 'max' ? 'max' : 'min'}(${m.group(2)})');

    // String concatenation: "text" + var → target style
    // Python: f-string would be ideal but keep simple for now
    // Java boolean literals
    if (t == 'python' || t == 'dart') {
      e = e.replaceAll(r'\btrue\b', 'True').replaceAll(r'\bfalse\b', 'False');
    }

    // ** operator for Python power
    // Python uses ** but Java/C use pow() — handled above

    // Integer division in Python: / → // for int types (heuristic: too complex, skip)

    return e;
  }

  // ─── Code generation helpers ──────────────────────────────────────────────

  String _varDecl(String jType, String name, String expr, String t) {
    final semi = _needsSemicolon(t) ? ';' : '';
    switch (t) {
      case 'python':
        return '$name = $expr';
      case 'java':
        return '        ${_javaType(jType)} $name = $expr$semi';
      case 'cpp':
      case 'c++':
        return '    ${_cppType(jType)} $name = $expr$semi';
      case 'c':
        return '    ${_cType(jType)} $name = $expr$semi';
      case 'javascript':
      case 'js':
        return '    let $name = $expr$semi';
      case 'typescript':
      case 'ts':
        return '    let $name: ${_tsType(jType)} = $expr$semi';
      case 'kotlin':
        return '    val $name = $expr';
      case 'swift':
        return '    let $name = $expr';
      case 'dart':
        return '  ${_dartType(jType)} $name = $expr$semi';
      case 'go':
        return '    $name := $expr';
      case 'rust':
        return '    let $name = $expr$semi';
      case 'csharp':
      case 'c#':
        return '        ${_csType(jType)} $name = $expr$semi';
      default:
        return '    $name = $expr$semi';
    }
  }

  String _varDeclOnly(String jType, String name, String t) {
    final semi = _needsSemicolon(t) ? ';' : '';
    switch (t) {
      case 'python':        return '$name = None';
      case 'java':          return '        ${_javaType(jType)} $name$semi';
      case 'cpp': case 'c++': return '    ${_cppType(jType)} $name$semi';
      case 'c':             return '    ${_cType(jType)} $name$semi';
      case 'javascript': case 'js': return '    let $name$semi';
      case 'kotlin':        return '    var $name: ${_kotlinType(jType)}? = null';
      case 'dart':          return '  ${_dartType(jType)}? $name$semi';
      default:              return '    $name$semi';
    }
  }

  String _pyVarDecl(String name, String expr, String t) {
    // Used when source is Python (untyped) — guess type from expr
    final jType = _guessType(expr);
    return _varDecl(jType, name, expr, t);
  }

  String _assignment(String name, String op, String expr, String t) {
    final semi = _needsSemicolon(t) ? ';' : '';
    final indent = _indent(t);
    return '$indent$name $op $expr$semi';
  }

  String _printLn(String arg, String t) {
    switch (t) {
      case 'python':        return 'print($arg)';
      case 'java':          return '        System.out.println($arg);';
      case 'cpp': case 'c++': return '    std::cout << $arg << std::endl;';
      case 'c':             return '    printf("%s\\n", $arg);';
      case 'javascript': case 'js': return '    console.log($arg);';
      case 'typescript': case 'ts': return '    console.log($arg);';
      case 'kotlin':        return '    println($arg)';
      case 'swift':         return '    print($arg)';
      case 'dart':          return '  print($arg);';
      case 'go':            return '    fmt.Println($arg)';
      case 'rust':          return '    println!("{}", $arg);';
      case 'ruby':          return 'puts $arg';
      case 'php':           return '    echo $arg . "\\n";';
      case 'csharp': case 'c#': return '        Console.WriteLine($arg);';
      case 'scala':         return '  println($arg)';
      case 'r':             return 'cat($arg, "\\n")';
      case 'bash':          return 'echo $arg';
      default:              return 'print($arg)';
    }
  }

  String _print(String arg, String t) {
    switch (t) {
      case 'python':        return 'print($arg, end="")';
      case 'java':          return '        System.out.print($arg);';
      case 'cpp': case 'c++': return '    std::cout << $arg;';
      case 'c':             return '    printf("%s", $arg);';
      case 'javascript': case 'js': return '    process.stdout.write(String($arg));';
      default:              return _printLn(arg, t);
    }
  }

  String _forLoop(String v, String start, String op, String end, String step,
      String body, String t) {
    final stepStr = step.trim() == '++' ? '$v++' :
                    step.trim() == '--' ? '$v--' : '$v$step';
    switch (t) {
      case 'python':
        if (start == '0') return 'for $v in range($end):';
        return 'for $v in range($start, $end):';
      case 'java':
        return '        for (int $v = $start; $v $op $end; $stepStr) {';
      case 'cpp': case 'c++':
        return '    for (int $v = $start; $v $op $end; $stepStr) {';
      case 'c':
        return '    for (int $v = $start; $v $op $end; $stepStr) {';
      case 'javascript': case 'js':
        return '    for (let $v = $start; $v $op $end; $stepStr) {';
      case 'typescript': case 'ts':
        return '    for (let $v = $start; $v $op $end; $stepStr) {';
      case 'kotlin':
        if (op == '<') return '    for ($v in $start until $end) {';
        if (op == '<=') return '    for ($v in $start..$end) {';
        return '    for ($v in $start until $end) {';
      case 'swift':
        if (op == '<') return '    for $v in $start..<$end {';
        if (op == '<=') return '    for $v in $start...$end {';
        return '    for $v in $start..<$end {';
      case 'dart':
        return '  for (int $v = $start; $v $op $end; $stepStr) {';
      case 'go':
        return '    for $v := $start; $v $op $end; $stepStr {';
      case 'rust':
        if (op == '<') return '    for $v in $start..$end {';
        if (op == '<=') return '    for $v in $start..=$end {';
        return '    for $v in $start..$end {';
      case 'csharp': case 'c#':
        return '        for (int $v = $start; $v $op $end; $stepStr) {';
      default:
        return '    for $v in range($start, $end):';
    }
  }

  String _whileLoop(String cond, String t) {
    switch (t) {
      case 'python':        return 'while $cond:';
      case 'java':          return '        while ($cond) {';
      case 'cpp': case 'c++': return '    while ($cond) {';
      case 'c':             return '    while ($cond) {';
      case 'javascript': case 'js': return '    while ($cond) {';
      case 'kotlin':        return '    while ($cond) {';
      case 'swift':         return '    while $cond {';
      case 'dart':          return '  while ($cond) {';
      case 'go':            return '    for $cond {';
      case 'rust':          return '    while $cond {';
      case 'csharp': case 'c#': return '        while ($cond) {';
      default:              return '    while ($cond):';
    }
  }

  String _ifStmt(String cond, String t) {
    switch (t) {
      case 'python':        return 'if $cond:';
      case 'java':          return '        if ($cond) {';
      case 'cpp': case 'c++': return '    if ($cond) {';
      case 'c':             return '    if ($cond) {';
      case 'javascript': case 'js': return '    if ($cond) {';
      case 'kotlin':        return '    if ($cond) {';
      case 'swift':         return '    if $cond {';
      case 'dart':          return '  if ($cond) {';
      case 'go':            return '    if $cond {';
      case 'rust':          return '    if $cond {';
      case 'csharp': case 'c#': return '        if ($cond) {';
      default:              return '    if ($cond) {';
    }
  }

  String _elseIfStmt(String cond, String t) {
    switch (t) {
      case 'python':        return 'elif $cond:';
      case 'java':          return '        } else if ($cond) {';
      case 'cpp': case 'c++': return '    } else if ($cond) {';
      case 'c':             return '    } else if ($cond) {';
      case 'javascript': case 'js': return '    } else if ($cond) {';
      case 'kotlin':        return '    } else if ($cond) {';
      case 'swift':         return '    } else if $cond {';
      case 'dart':          return '  } else if ($cond) {';
      case 'go':            return '    } else if $cond {';
      case 'rust':          return '    } else if $cond {';
      case 'csharp': case 'c#': return '        } else if ($cond) {';
      default:              return '    } else if ($cond) {';
    }
  }

  String _elseStmt(String t) {
    switch (t) {
      case 'python':        return 'else:';
      case 'java':          return '        } else {';
      case 'cpp': case 'c++': return '    } else {';
      case 'c':             return '    } else {';
      case 'javascript': case 'js': return '    } else {';
      case 'kotlin':        return '    } else {';
      case 'swift':         return '    } else {';
      case 'dart':          return '  } else {';
      case 'go':            return '    } else {';
      case 'rust':          return '    } else {';
      case 'csharp': case 'c#': return '        } else {';
      default:              return '    } else {';
    }
  }

  String _returnStmt(String val, String t) {
    final semi = _needsSemicolon(t) ? ';' : '';
    final indent = _indent(t);
    return '${indent}return $val$semi';
  }

  String _openBrace(String t) {
    if (t == 'python') return '';   // Python uses indentation
    return '';  // Handled by block starters already including {
  }

  String _closeBrace(String t) {
    if (t == 'python') return '';
    return _indent(t) + '}';
  }

  String _commentFor(String text, String t) {
    if (t == 'python' || t == 'ruby' || t == 'bash' || t == 'r' || t == 'perl') {
      return '# $text';
    }
    return '// $text';
  }

  String _funcDef(String name, String params, String t) {
    switch (t) {
      case 'python':        return 'def $name($params):';
      case 'java':          return '    public static void $name($params) {';
      case 'cpp': case 'c++': return 'void $name($params) {';
      case 'c':             return 'void $name($params) {';
      case 'javascript': case 'js': return 'function $name($params) {';
      case 'typescript': case 'ts': return 'function $name($params): void {';
      case 'kotlin':        return 'fun $name($params) {';
      case 'swift':         return 'func $name($params) {';
      case 'dart':          return 'void $name($params) {';
      case 'go':            return 'func $name($params) {';
      case 'rust':          return 'fn $name($params) {';
      case 'csharp': case 'c#': return '    static void $name($params) {';
      default:              return 'function $name($params) {';
    }
  }

  // ─── Wrap body in main / includes ─────────────────────────────────────────

  String _wrapInMain(List<String> body, String t) {

    switch (t) {
      case 'python':
        return body.join('\n');

      case 'java':
        return 'public class Main {\n'
            '    public static void main(String[] args) {\n'
            '${body.map((l) => l.isEmpty ? '' : '        $l').join('\n')}\n'
            '    }\n}';

      case 'cpp':
      case 'c++':
        final needsMath = body.any((l) => l.contains('pow(') || l.contains('sqrt('));
        final needsString = body.any((l) => l.contains('std::string') || l.contains('"'));
        final includes = '#include <iostream>\n'
            '${needsMath ? '#include <cmath>\n' : ''}'
            '${needsString ? '#include <string>\n' : ''}'
            'using namespace std;\n';
        return '${includes}\nint main() {\n'
            '${body.map((l) => l.isEmpty ? '' : '    $l').join('\n')}\n'
            '    return 0;\n}';

      case 'c':
        final needsMathC = body.any((l) => l.contains('pow(') || l.contains('sqrt('));
        return '#include <stdio.h>\n'
            '${needsMathC ? '#include <math.h>\n' : ''}'
            '\nint main() {\n'
            '${body.map((l) => l.isEmpty ? '' : '    $l').join('\n')}\n'
            '    return 0;\n}';

      case 'javascript':
      case 'js':
        return body.map((l) => l.isEmpty ? '' : '  $l').join('\n');

      case 'typescript':
      case 'ts':
        return body.map((l) => l.isEmpty ? '' : '  $l').join('\n');

      case 'kotlin':
        return 'fun main() {\n'
            '${body.map((l) => l.isEmpty ? '' : '    $l').join('\n')}\n}';

      case 'swift':
        return body.join('\n');

      case 'dart':
        return 'void main() {\n'
            '${body.map((l) => l.isEmpty ? '' : '  $l').join('\n')}\n}';

      case 'go':
        final needsFmt = body.any((l) => l.contains('fmt.'));
        final needsMathGo = body.any((l) => l.contains('math.'));
        return 'package main\n\n'
            'import (\n'
            '${needsFmt ? '    "fmt"\n' : ''}'
            '${needsMathGo ? '    "math"\n' : ''}'
            ')\n\n'
            'func main() {\n'
            '${body.map((l) => l.isEmpty ? '' : '    $l').join('\n')}\n}';

      case 'rust':
        return 'fn main() {\n'
            '${body.map((l) => l.isEmpty ? '' : '    $l').join('\n')}\n}';

      case 'ruby':
        return body.join('\n');

      case 'php':
        return '<?php\n${body.join('\n')}\n?>';

      case 'csharp':
      case 'c#':
        final needsMathCs = body.any((l) => l.contains('Math.'));
        return 'using System;\n'
            '${needsMathCs ? '' : ''}'
            '\nclass Program {\n'
            '    static void Main() {\n'
            '${body.map((l) => l.isEmpty ? '' : '        $l').join('\n')}\n'
            '    }\n}';

      case 'scala':
        return 'object Main extends App {\n'
            '${body.map((l) => l.isEmpty ? '' : '  $l').join('\n')}\n}';

      case 'r':
        return body.join('\n');

      case 'bash':
        return '#!/bin/bash\n${body.join('\n')}';

      default:
        return body.join('\n');
    }
  }

  // ─── Type mappings ─────────────────────────────────────────────────────────

  String _javaType(String t) {
    switch (t) {
      case 'boolean': return 'boolean';
      case 'String':  return 'String';
      default:        return t;
    }
  }

  String _cppType(String t) {
    switch (t) {
      case 'boolean': case 'bool': return 'bool';
      case 'String':  return 'std::string';
      case 'long':    return 'long long';
      default:        return t;
    }
  }

  String _cType(String t) {
    switch (t) {
      case 'boolean': case 'bool': return 'int';
      case 'String':  return 'char*';
      case 'long':    return 'long';
      default:        return t;
    }
  }

  String _tsType(String t) {
    switch (t) {
      case 'int': case 'long': case 'double': case 'float': return 'number';
      case 'boolean': case 'bool': return 'boolean';
      case 'String':  return 'string';
      default:        return 'any';
    }
  }

  String _dartType(String t) {
    switch (t) {
      case 'int': case 'long': return 'int';
      case 'double': case 'float': return 'double';
      case 'boolean': case 'bool': return 'bool';
      case 'String':  return 'String';
      default:        return 'var';
    }
  }

  String _kotlinType(String t) {
    switch (t) {
      case 'int':     return 'Int';
      case 'long':    return 'Long';
      case 'double':  return 'Double';
      case 'float':   return 'Float';
      case 'boolean': return 'Boolean';
      case 'String':  return 'String';
      case 'char':    return 'Char';
      default:        return 'Any';
    }
  }

  String _csType(String t) {
    switch (t) {
      case 'boolean': case 'bool': return 'bool';
      case 'String':  return 'string';
      case 'long':    return 'long';
      default:        return t;
    }
  }

  String _guessType(String expr) {
    final e = expr.trim();
    if (e.contains('.') && double.tryParse(e) != null) return 'double';
    if (int.tryParse(e) != null) return 'int';
    if (e == 'true' || e == 'false') return 'boolean';
    if (e.startsWith('"') || e.startsWith("'")) return 'String';
    return 'var';
  }

  bool _needsSemicolon(String t) {
    return !(t == 'python' || t == 'ruby' || t == 'bash' ||
        t == 'kotlin' || t == 'swift' || t == 'go' || t == 'rust' ||
        t == 'scala');
  }

  String _indent(String t) {
    switch (t) {
      case 'java': case 'csharp': case 'c#': return '        ';
      case 'dart': return '  ';
      case 'python': case 'ruby': case 'bash': case 'r': return '';
      default: return '    ';
    }
  }


  String _unsupported() {
    return '// Auto-conversion from $from to $to is not supported offline.\n'
        '// Please use a valid Gemini API key for this language pair.\n\n'
        '/*\nOriginal code:\n\n$source\n*/';
  }
}
