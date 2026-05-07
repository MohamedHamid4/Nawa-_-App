import '../../core/errors/result.dart';

class AiSuggestions {
  final List<String> tags;
  final String? title;
  final String? category;
  const AiSuggestions({
    this.tags = const [],
    this.title,
    this.category,
  });
}

abstract class AiService {
  Future<Result<String>> summarize(String input, {String language = 'en'});
  Future<Result<List<String>>> extractTasks(String input, {String language = 'en'});
  Future<Result<AiSuggestions>> suggest(String input, {String language = 'en'});
  Future<Result<String>> complete(String input, {String language = 'en'});
}
