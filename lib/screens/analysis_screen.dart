import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/firestore_database.dart';
import '../services/code_analyzer_service.dart';
import '../services/code_execution_service.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _codeController = TextEditingController();

  String _language = 'Python';
  bool _isAnalyzing = false;

  // Results
  String _staticResult = '';
  String _executionOutput = '';
  String _executionError = '';
  String _compileError = '';
  String _statusDescription = '';
  bool _hasResult = false;
  bool _executionSupported = true;

  /// Languages supported by Judge0 (execution) — used for the dropdown
  final List<String> _languages = [
    'C',
    'C++',
    'C#',
    'Dart',
    'Go',
    'Java',
    'JavaScript',
    'Kotlin',
    'PHP',
    'Python',
    'Ruby',
    'Rust',
    'Swift',
    'TypeScript',
  ];

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _analyzeCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showSnack('Please enter some code to analyze.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _hasResult = false;
      _staticResult = '';
      _executionOutput = '';
      _executionError = '';
      _compileError = '';
      _statusDescription = '';
      _executionSupported = true;
    });

    // 1. Static analysis (instant, local)
    final staticResult = CodeAnalyzerService.analyzeCode(code, _language);

    // 2. Live execution via Judge0
    String execOutput = '';
    String execError = '';
    String compileErr = '';
    String statusDesc = '';
    bool execSupported = true;

    final langId = CodeExecutionService.getLanguageId(_language);
    if (langId == null) {
      execSupported = false;
    } else {
      try {
        final result =
            await CodeExecutionService.executeCode(code, _language);
        execOutput = result.stdout;
        execError = result.stderr;
        compileErr = result.compileOutput ?? '';
        statusDesc = result.statusDescription;
      } catch (e) {
        execError = 'Execution failed: $e';
        statusDesc = 'Error';
      }
    }

    if (!mounted) return;

    setState(() {
      _staticResult = staticResult;
      _executionOutput = execOutput;
      _executionError = execError;
      _compileError = compileErr;
      _statusDescription = statusDesc;
      _executionSupported = execSupported;
      _isAnalyzing = false;
      _hasResult = true;
    });

    // Save to Firestore history
    final fullResult =
        'Static: $staticResult\n\nExecution [$statusDesc]: '
        '${execOutput.isNotEmpty ? execOutput : execError}';
    try {
      await FirestoreDatabase.saveAnalysisResult(
        codeSnippet: code,
        language: _language,
        result: fullResult,
      );
    } catch (_) {
      // Don't block UI on save failure
    }
  }

  void _clear() {
    setState(() {
      _codeController.clear();
      _hasResult = false;
      _staticResult = '';
      _executionOutput = '';
      _executionError = '';
      _compileError = '';
      _statusDescription = '';
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Code Analysis'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Language picker
              const Text('Select language:',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _language,
                decoration: const InputDecoration(
                  labelText: 'Language',
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
                items: _languages
                    .map((l) =>
                        DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _language = v;
                      _hasResult = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Code input
              const Text('Paste your code snippet:',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              CustomTextField(
                controller: _codeController,
                labelText: 'Code Snippet',
                hintText: 'Enter or paste code here...',
                maxLines: 15,
                isCode: true,
              ),
              const SizedBox(height: 16),

              // Buttons
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomButton(
                      text: _isAnalyzing ? 'Analyzing...' : 'Analyze & Run',
                      onPressed: _isAnalyzing ? () {} : _analyzeCode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing ? null : _clear,
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      label: const Text('Clear',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Results
              if (_isAnalyzing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Running on Judge0...',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else if (_hasResult) ...[
                _buildStaticSection(),
                const SizedBox(height: 16),
                _buildExecutionSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Result Sections ───────────────────────────────────────────────────────

  Widget _buildStaticSection() {
    final isClean = _staticResult.startsWith('✅');
    final color = isClean ? Colors.green : Colors.amber;
    final borderColor = isClean ? Colors.green : Colors.amber;

    return _resultCard(
      title: '🔍 Static Analysis',
      body: _staticResult,
      borderColor: borderColor,
      bgColor: color.withOpacity(0.07),
      leading: Icon(
        isClean ? Icons.check_circle_outline : Icons.warning_amber_rounded,
        color: color,
      ),
    );
  }

  Widget _buildExecutionSection() {
    if (!_executionSupported) {
      return _resultCard(
        title: '⚙️ Execution (Judge0)',
        body: 'Execution is not available for $_language via Judge0.',
        borderColor: Colors.grey,
        bgColor: Colors.grey.withOpacity(0.07),
        leading: const Icon(Icons.block, color: Colors.grey),
      );
    }

    // Compile error
    if (_compileError.isNotEmpty) {
      return _resultCard(
        title: '⚙️ Execution — Compile Error',
        body: _compileError,
        borderColor: Colors.red,
        bgColor: Colors.red.withOpacity(0.06),
        leading: const Icon(Icons.build_circle_outlined, color: Colors.red),
        statusBadge: _statusDescription,
        statusColor: Colors.red,
      );
    }

    // Runtime error
    if (_executionError.isNotEmpty) {
      return _resultCard(
        title: '⚙️ Execution — Runtime Error',
        body: _executionError,
        borderColor: Colors.orange,
        bgColor: Colors.orange.withOpacity(0.06),
        leading:
            const Icon(Icons.error_outline, color: Colors.orange),
        statusBadge: _statusDescription,
        statusColor: Colors.orange,
      );
    }

    // Success
    final output =
        _executionOutput.isEmpty ? '(no output)' : _executionOutput;
    return _resultCard(
      title: '⚙️ Execution — Success',
      body: output,
      borderColor: Colors.green,
      bgColor: Colors.green.withOpacity(0.07),
      leading:
          const Icon(Icons.play_circle_outline, color: Colors.green),
      statusBadge: _statusDescription,
      statusColor: Colors.green,
      isCode: true,
    );
  }

  Widget _resultCard({
    required String title,
    required String body,
    required Color borderColor,
    required Color bgColor,
    required Widget leading,
    String? statusBadge,
    Color? statusColor,
    bool isCode = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              leading,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: borderColor,
                  ),
                ),
              ),
              if (statusBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (statusColor ?? borderColor).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusBadge,
                    style: TextStyle(
                        fontSize: 11,
                        color: statusColor ?? borderColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const Divider(height: 16),
          Text(
            body,
            style: TextStyle(
              fontFamily: isCode ? 'monospace' : null,
              fontSize: isCode ? 13 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
