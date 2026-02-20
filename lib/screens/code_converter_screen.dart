import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_button.dart';
import '../services/code_converter_service.dart';

class CodeConverterScreen extends StatefulWidget {
  const CodeConverterScreen({super.key});

  @override
  State<CodeConverterScreen> createState() => _CodeConverterScreenState();
}

class _CodeConverterScreenState extends State<CodeConverterScreen> {
  final _inputController = TextEditingController();
  final _outputController = TextEditingController();

  String _fromLang = 'Python';
  String _toLang = 'JavaScript';
  bool _isConverting = false;
  bool _hasResult = false;

  final List<String> _languages = [
    'Python',
    'JavaScript',
    'TypeScript',
    'Java',
    'Kotlin',
    'Dart',
    'C++',
    'C',
    'C#',
    'Go',
    'Rust',
    'Swift',
    'PHP',
    'Ruby',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _convert() async {
    final code = _inputController.text.trim();
    if (code.isEmpty) {
      _showSnack('Please enter some code to convert.');
      return;
    }

    setState(() {
      _isConverting = true;
      _hasResult = false;
      _outputController.clear();
    });

    try {
      final result =
          await CodeConverterService.convertCode(code, _fromLang, _toLang);
      if (mounted) {
        setState(() {
          _outputController.text = result;
          _isConverting = false;
          _hasResult = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConverting = false);
        _showSnack('Conversion error: $e');
      }
    }
  }

  void _swapLanguages() {
    setState(() {
      final temp = _fromLang;
      _fromLang = _toLang;
      _toLang = temp;

      // Also swap text content if there's a result
      if (_hasResult) {
        final tempText = _inputController.text;
        _inputController.text = _outputController.text;
        _outputController.text = tempText;
      }
    });
  }

  void _copyToClipboard() {
    final text = _outputController.text;
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('Copied to clipboard!');
  }

  void _clear() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _hasResult = false;
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Code Converter'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Language selector row ──────────────────────────────────────
              _buildLanguageRow(theme),
              const SizedBox(height: 20),

              // ── Input area ────────────────────────────────────────────────
              _buildSectionLabel('Input Code ($_fromLang)'),
              const SizedBox(height: 8),
              _buildCodeInput(isDark),
              const SizedBox(height: 16),

              // ── Action buttons ────────────────────────────────────────────
              _buildActionRow(),
              const SizedBox(height: 20),

              // ── Output area ───────────────────────────────────────────────
              if (_isConverting) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Converting...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ] else if (_hasResult) ...[
                _buildOutputHeader(theme),
                const SizedBox(height: 8),
                _buildCodeOutput(isDark),
              ],


            ],
          ),
        ),
      ),
    );
  }

  // ─── Language Row ──────────────────────────────────────────────────────────

  Widget _buildLanguageRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _buildDropdown('From', _fromLang, (v) {
          if (v != null && v != _toLang) setState(() => _fromLang = v);
        })),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Tooltip(
            message: 'Swap languages',
            child: InkWell(
              onTap: _swapLanguages,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withOpacity(0.1),
                ),
                child: Icon(Icons.swap_horiz,
                    color: theme.primaryColor, size: 28),
              ),
            ),
          ),
        ),
        Expanded(child: _buildDropdown('To', _toLang, (v) {
          if (v != null && v != _fromLang) setState(() => _toLang = v);
        })),
      ],
    );
  }

  Widget _buildDropdown(
      String label, String value, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      isExpanded: true,
      items: _languages
          .map((l) => DropdownMenuItem(value: l, child: Text(l)))
          .toList(),
      onChanged: onChanged,
    );
  }

  // ─── Input Area ────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));
  }

  Widget _buildCodeInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: TextField(
        controller: _inputController,
        maxLines: 14,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'Paste your code here...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
        ),
      ),
    );
  }

  // ─── Action Row ────────────────────────────────────────────────────────────

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: CustomButton(
            text: _isConverting ? 'Converting...' : 'Convert',
            onPressed: _isConverting ? () {} : _convert,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: _isConverting ? null : _clear,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label:
                const Text('Clear', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Output Area ───────────────────────────────────────────────────────────

  Widget _buildOutputHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionLabel('Output Code ($_toLang)'),
        IconButton(
          tooltip: 'Copy to clipboard',
          icon: Icon(Icons.copy, color: theme.primaryColor),
          onPressed: _copyToClipboard,
        ),
      ],
    );
  }

  Widget _buildCodeOutput(bool isDark) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: TextField(
        controller: _outputController,
        readOnly: true,
        maxLines: null,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
        ),
      ),
    );
  }

  // ─── Info Card ─────────────────────────────────────────────────────────────

 
}
