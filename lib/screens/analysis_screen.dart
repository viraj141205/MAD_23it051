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
  String _language = 'Java';
  String _analysisResult = '';
  bool _isAnalyzing = false;
  bool _isLoading = false; // Added _isLoading

  final List<String> _languages = [
    'Java',
    'C++',
    'Python',
    'JavaScript',
    'Dart',
    'Go',
    'Rust',
    'Swift',
    'Kotlin',
    'PHP',
    'C#',
    'Ruby',
    'C',
    'HTML/CSS',
    'SQL',
    'TypeScript',
    'Other'
  ];

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _analyzeCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some code to analyze.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = '';
    });

    // Simplified analysis delay for better UX
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _isLoading = true);

    final staticAnalysis = CodeAnalyzerService.analyzeCode(code, _language);
    
    // Check if we can run this language
    final pistonLang = CodeExecutionService.getPistonLanguage(_language);
    String executionFeedback = '';

    if (pistonLang != null) {
      final result = await CodeExecutionService.executeCode(code, _language);
      if (result != null) {
        if (result.compileOutput != null && result.compileOutput!.isNotEmpty) {
          executionFeedback = '\n\n❌ Compiler Errors:\n${result.compileOutput}';
        } else if (result.stderr.isNotEmpty) {
          executionFeedback = '\n\n❌ Runtime Errors:\n${result.stderr}';
        } else {
          executionFeedback = '\n\n✅ Execution Successful!\nOutput:\n${result.stdout}';
        }
      } else {
        executionFeedback = '\n\n⚠️ Execution failed (server error or timeout).';
      }
    } else {
      executionFeedback = '\n\nℹ️ Execution is not supported for this language yet.';
    }

    setState(() {
      _analysisResult = staticAnalysis + executionFeedback;
      _isLoading = false;
      _isAnalyzing = false; // Ensure _isAnalyzing is also reset
    });
    // Save to history
    try {
        await FirestoreDatabase.saveAnalysisResult(
          codeSnippet: code,
          language: _language,
          result: _analysisResult,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Analysis saved to history'), duration: Duration(seconds: 1)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving to history: $e')),
          );
        }
      }
    }
  }

  void _clear() {
    setState(() {
      _codeController.clear();
      _analysisResult = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Code Analysis'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select programming language:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _language,
                decoration: const InputDecoration(
                  labelText: 'Language',
                  border: OutlineInputBorder(),
                ),
                items: _languages
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _language = value;
                      _codeController.clear();
                      _analysisResult = '';
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Paste your code snippet below:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _codeController,
                labelText: 'Code Snippet',
                hintText: 'Enter or paste code here...',
                maxLines: 15, // Increased for better code visibility
                isCode: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Analyze',
                      onPressed: _isAnalyzing ? () {} : _analyzeCode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isAnalyzing ? null : _clear,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Clear', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isAnalyzing)
                const Center(child: CircularProgressIndicator())
              else if (_analysisResult.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _analysisResult.startsWith('✅') ? Colors.green[50] : (_analysisResult.startsWith('❌') ? Colors.red[50] : Colors.amber[50]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _analysisResult.startsWith('✅') ? Colors.green : (_analysisResult.startsWith('❌') ? Colors.red : Colors.amber),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analysis Result:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_analysisResult),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
