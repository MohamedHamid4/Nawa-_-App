import 'package:google_generative_ai/google_generative_ai.dart';

import '../../config/env.dart';
import '../../domain/repositories/ai_service.dart';
import '../errors/failures.dart';
import '../errors/result.dart';
import '../utils/app_logger.dart';

/// Gemini-backed AI service. Uses Google's free tier (15 requests/min).
/// Falls back to lightweight local heuristics when the key is missing or the
/// request fails so the app keeps working offline.
class HttpAiService implements AiService {
  GenerativeModel? _model;

  HttpAiService() {
    if (Env.geminiApiKey.isNotEmpty) {
      try {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: Env.geminiApiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 1024,
          ),
        );
      } catch (e) {
        AppLogger.w('Gemini init failed: $e');
      }
    }
  }

  bool get _configured => _model != null;

  @override
  Future<Result<String>> summarize(String input,
      {String language = 'en'}) async {
    if (input.trim().length < 30) {
      return FailureResult(const AiFailure('text_too_short'));
    }
    if (!_configured) {
      return FailureResult(const AiFailure('api_key_invalid'));
    }
    try {
      final prompt = language == 'ar'
          ? 'لخّص النص التالي بالعربية الفصحى في 2-3 جمل واضحة ومفيدة. ركّز على الأفكار الرئيسية فقط:\n\n$input'
          : 'Summarize the following text in 2-3 clear, useful sentences. Focus on main ideas only:\n\n$input';
      final response = await _model!.generateContent([Content.text(prompt)]);
      final summary = response.text?.trim();
      if (summary == null || summary.isEmpty) {
        return FailureResult(const AiFailure('empty_response'));
      }
      return Success(summary);
    } catch (e, st) {
      AppLogger.e('Gemini summarize failed', e, st);
      final msg = e.toString().toLowerCase();
      if (msg.contains('api_key') ||
          msg.contains('api key') ||
          msg.contains('unauthorized') ||
          msg.contains('401')) {
        return FailureResult(AiFailure('api_key_invalid', cause: e));
      }
      if (msg.contains('quota') ||
          msg.contains('429') ||
          msg.contains('rate limit')) {
        return FailureResult(AiFailure('quota_exceeded', cause: e));
      }
      if (msg.contains('socketexception') ||
          msg.contains('networkexception') ||
          msg.contains('failed host lookup') ||
          msg.contains('handshake')) {
        return FailureResult(AiFailure('no_internet', cause: e));
      }
      if (msg.contains('safety') || msg.contains('blocked')) {
        return FailureResult(AiFailure('blocked', cause: e));
      }
      return FailureResult(AiFailure('unknown', cause: e));
    }
  }

  @override
  Future<Result<List<String>>> extractTasks(String input,
      {String language = 'en'}) async {
    if (!_configured) {
      return Success(_localFallbackTasks(input));
    }
    try {
      final prompt = language == 'ar'
          ? 'استخرج قائمة مهام واضحة من هذا النص. أعد كل مهمة في سطر منفصل بدون ترقيم أو نقاط:\n\n$input'
          : 'Extract a clear task list from this text. Return each task on a separate line, no numbering or bullets:\n\n$input';
      final response = await _model!.generateContent([Content.text(prompt)]);
      final raw = response.text?.trim() ?? '';
      if (raw.isEmpty) return Success(_localFallbackTasks(input));
      final tasks = raw
          .split('\n')
          .map((line) =>
              line.replaceAll(RegExp(r'^[\d\.\-\*\•]+\s*'), '').trim())
          .where((s) => s.length > 2)
          .take(20)
          .toList();
      if (tasks.isEmpty) return Success(_localFallbackTasks(input));
      return Success(tasks);
    } catch (e) {
      AppLogger.w('Gemini extractTasks failed: $e');
      return Success(_localFallbackTasks(input));
    }
  }

  @override
  Future<Result<AiSuggestions>> suggest(String input,
      {String language = 'en'}) async {
    if (!_configured) {
      return Success(_localSuggestions(input));
    }
    try {
      final prompt = language == 'ar'
          ? 'اقترح: عنوان قصير (5 كلمات أو أقل)، 3 وسوم، فئة. أعد JSON بالشكل: {"title":"","tags":[],"category":""}\n\n$input'
          : 'Suggest: short title (5 words max), 3 tags, category. Return JSON: {"title":"","tags":[],"category":""}\n\n$input';
      final response = await _model!.generateContent([Content.text(prompt)]);
      final raw = response.text?.trim() ?? '';
      final jsonMatch =
          RegExp(r'\{[^}]*"title"[^}]*\}', dotAll: true).firstMatch(raw);
      if (jsonMatch == null) return Success(_localSuggestions(input));
      final json = jsonMatch.group(0)!;
      final titleMatch = RegExp(r'"title"\s*:\s*"([^"]*)"').firstMatch(json);
      final categoryMatch =
          RegExp(r'"category"\s*:\s*"([^"]*)"').firstMatch(json);
      final tagsMatch =
          RegExp(r'"tags"\s*:\s*\[([^\]]*)\]').firstMatch(json);
      final tags = <String>[];
      if (tagsMatch != null) {
        for (final m in RegExp(r'"([^"]+)"').allMatches(tagsMatch.group(1)!)) {
          tags.add(m.group(1)!);
        }
      }
      return Success(AiSuggestions(
        title: titleMatch?.group(1),
        category: categoryMatch?.group(1),
        tags: tags,
      ));
    } catch (e) {
      AppLogger.w('Gemini suggest failed: $e');
      return Success(_localSuggestions(input));
    }
  }

  @override
  Future<Result<String>> complete(String input,
      {String language = 'en'}) async {
    if (!_configured) {
      return FailureResult(const NetworkFailure());
    }
    try {
      final response = await _model!.generateContent([Content.text(input)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return FailureResult(const ServerFailure());
      }
      return Success(text);
    } catch (e) {
      AppLogger.w('Gemini complete failed: $e');
      return FailureResult(const ServerFailure());
    }
  }

  /// Suggest the best reminder time based on note content. Returns null on failure.
  Future<DateTime?> suggestReminderTime(String noteContent) async {
    if (!_configured) return null;
    try {
      final now = DateTime.now();
      final prompt = '''Analyze this note and suggest the best reminder time.
Current time: ${now.toIso8601String()}
Note: $noteContent

Return ONLY a datetime in ISO 8601 format (YYYY-MM-DDTHH:MM:SS), nothing else.
If unsure, suggest tomorrow at 9 AM.''';
      final response = await _model!.generateContent([Content.text(prompt)]);
      final raw = response.text?.trim() ?? '';
      final match =
          RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2})?').firstMatch(raw);
      if (match == null) return null;
      return DateTime.tryParse(match.group(0)!);
    } catch (e) {
      AppLogger.w('Gemini suggestReminderTime failed: $e');
      return null;
    }
  }

  // ── Local fallbacks ──────────────────────────────────────
  List<String> _localFallbackTasks(String input) {
    final clean = input.replaceAll('\n', ' ').trim();
    if (clean.isEmpty) return [];
    final parts = clean.split(RegExp(r'\s+(?:و|ثم|and|then)\s+|[.,;،؛]'));
    return parts
        .map((p) => p.trim())
        .where((p) => p.length > 2)
        .take(20)
        .toList();
  }

  AiSuggestions _localSuggestions(String input) {
    final words = input
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 4)
        .toSet()
        .take(5)
        .toList();
    final firstSentence = input.split(RegExp(r'[.!?؟\n]')).first.trim();
    final title = firstSentence.length > 60
        ? '${firstSentence.substring(0, 60)}…'
        : firstSentence;
    return AiSuggestions(tags: words, title: title);
  }
}
