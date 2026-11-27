import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_scope.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/generated/app_l10n.dart';

/// Documento legal que se abre desde los ajustes.
enum LegalDocumentKind { privacy, terms }

/// Ruta del asset según idioma. Cualquier idioma que no sea español cae al inglés.
String legalAssetPath(LegalDocumentKind kind, String language) {
  final suffix = language == 'es' ? 'es' : 'en';
  return 'assets/legal/${kind.name}_$suffix.md';
}

enum LegalBlockKind { heading1, heading2, bullet, paragraph }

class LegalBlock {
  const LegalBlock(this.kind, this.text);

  final LegalBlockKind kind;
  final String text;
}

/// Renderizador mínimo de Markdown (# , ## , - , párrafos y **negrita**).
abstract final class LegalMarkdown {
  static List<LegalBlock> parse(String markdown) {
    final blocks = <LegalBlock>[];
    final buffer = StringBuffer();

    void flush() {
      final text = buffer.toString().trim();
      if (text.isNotEmpty) blocks.add(LegalBlock(LegalBlockKind.paragraph, text));
      buffer.clear();
    }

    for (final rawLine in markdown.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        flush();
      } else if (line.startsWith('## ')) {
        flush();
        blocks.add(LegalBlock(LegalBlockKind.heading2, line.substring(3)));
      } else if (line.startsWith('# ')) {
        flush();
        blocks.add(LegalBlock(LegalBlockKind.heading1, line.substring(2)));
      } else if (line.startsWith('- ')) {
        flush();
        blocks.add(LegalBlock(LegalBlockKind.bullet, line.substring(2)));
      } else {
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(line);
      }
    }
    flush();
    return blocks;
  }

  static List<TextSpan> spans(String text) {
    final spans = <TextSpan>[];
    final bold = RegExp(r'\*\*(.*?)\*\*');
    var start = 0;
    for (final match in bold.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }
}

class LegalDocumentView extends StatelessWidget {
  const LegalDocumentView({super.key, required this.markdown});

  final String markdown;

  Widget _block(BuildContext context, LegalBlock block) {
    final theme = Theme.of(context).textTheme;
    final rich = SelectableText.rich(
      TextSpan(children: LegalMarkdown.spans(block.text)),
      style: switch (block.kind) {
        LegalBlockKind.heading1 => theme.headlineSmall,
        LegalBlockKind.heading2 => theme.titleMedium,
        LegalBlockKind.bullet || LegalBlockKind.paragraph => theme.bodyMedium,
      },
    );
    if (block.kind == LegalBlockKind.bullet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SelectableText('• '),
          Expanded(child: rich),
        ],
      );
    }
    return rich;
  }

  @override
  Widget build(BuildContext context) {
    final blocks = LegalMarkdown.parse(markdown);
    return ListView.separated(
      itemCount: blocks.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _block(context, blocks[index]),
    );
  }
}

class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({super.key, required this.kind});

  final LegalDocumentKind kind;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  late String _assetPath;
  late Future<String> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppScope.of(context).settings;
    final language = switch (settings.language) {
      AppLanguage.spanish => 'es',
      AppLanguage.english => 'en',
      AppLanguage.system =>
        Localizations.localeOf(context).languageCode == 'es' ? 'es' : 'en',
    };
    final path = legalAssetPath(widget.kind, language);
    if (!_initialized || path != _assetPath) {
      _assetPath = path;
      _future = rootBundle.loadString(path);
      _initialized = true;
    }
  }

  String _title(L10n l10n) => switch (widget.kind) {
        LegalDocumentKind.privacy => l10n.legalPrivacyTitle,
        LegalDocumentKind.terms => l10n.legalTermsTitle,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return AppScaffold(
      appBar: AppBar(title: Text(_title(l10n))),
      body: FutureBuilder<String>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError ||
              (snapshot.connectionState == ConnectionState.done &&
                  snapshot.data == null)) {
            return Center(child: Text(l10n.legalDocumentUnavailable));
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return LegalDocumentView(markdown: snapshot.data ?? '');
        },
      ),
    );
  }
}
