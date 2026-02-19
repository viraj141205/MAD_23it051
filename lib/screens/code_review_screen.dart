import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/code_review_service.dart';

class CodeReviewScreen extends StatefulWidget {
  const CodeReviewScreen({super.key});

  @override
  State<CodeReviewScreen> createState() => _CodeReviewScreenState();
}

class _CodeReviewScreenState extends State<CodeReviewScreen> {
  final _codeController = TextEditingController();
  String _language = 'Java';
  Map<String, List<String>> _reviewResults = {};
  bool _isReviewing = false;

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
    'TypeScript',
    'Other'
  ];

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _reviewCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some code to review.')),
      );
      return;
    }

    setState(() {
      _isReviewing = true;
      _reviewResults = {};
    });

    try {
      final results = await CodeReviewService.reviewCode(code, _language);

      if (mounted) {
        setState(() {
          _reviewResults = results;
          _isReviewing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isReviewing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during review: $e')),
        );
      }
    }
  }

  void _clear() {
    setState(() {
      _codeController.clear();
      _reviewResults = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Code Review'),
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
                        _reviewResults = {};
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Paste your code for review:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _codeController,
                  labelText: 'Code',
                  hintText: 'Enter code here...',
                  maxLines: 12,
                  isCode: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Review',
                        onPressed: _isReviewing ? () {} : _reviewCode,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isReviewing ? null : _clear,
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
                if (_isReviewing)
                  const Center(child: CircularProgressIndicator())
                else if (_reviewResults.isNotEmpty)
                  _buildReviewResults(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewResults() {
    final hasIssues = _reviewResults.values.any((list) => list.isNotEmpty);

    if (!hasIssues) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Expanded(child: Text('No major issues found! Your code looks good.')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_reviewResults['critical']!.isNotEmpty)
          _buildResultSection('Critical Issues', _reviewResults['critical']!, Colors.red),
        if (_reviewResults['security']!.isNotEmpty)
          _buildResultSection('Security', _reviewResults['security']!, Colors.orange),
        if (_reviewResults['best_practices']!.isNotEmpty)
          _buildResultSection('Best Practices', _reviewResults['best_practices']!, Colors.blue),
        if (_reviewResults['suggestions']!.isNotEmpty)
          _buildResultSection('Suggestions', _reviewResults['suggestions']!, Colors.green),
      ],
    );
  }

  Widget _buildResultSection(String title, List<String> items, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        leading: Icon(
          title == 'Critical Issues' ? Icons.error : (title == 'Security' ? Icons.security : Icons.lightbulb),
          color: color,
        ),
        children: items.map((item) => ListTile(
          leading: const Icon(Icons.arrow_right, size: 20),
          title: Text(item, style: const TextStyle(fontSize: 14)),
          dense: true,
        )).toList(),
      ),
    );
  }
}
