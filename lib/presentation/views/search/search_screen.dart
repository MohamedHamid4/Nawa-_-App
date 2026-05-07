import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/note.dart';
import '../../widgets/common/empty_state.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Note> _results = [];
  String _query = '';
  bool _searching = false;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: AppLimits.searchDebounceMs),
      () => _runSearch(value),
    );
  }

  Future<void> _runSearch(String value) async {
    setState(() {
      _query = value;
      _searching = true;
    });
    final repo = ref.read(noteRepositoryProvider);
    final r = await repo.search(value);
    final list = r.dataOrNull ?? const <Note>[];
    if (!mounted) return;
    setState(() {
      _results = list;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: 'search.hint'.tr(),
            border: InputBorder.none,
            filled: false,
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                _onChanged('');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? EmptyState(
              icon: Icons.search,
              title: 'search.title'.tr(),
              subtitle: 'search.tap_to_search'.tr(),
            )
          : _searching
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? EmptyState(
                      icon: Icons.sentiment_dissatisfied,
                      title: 'search.no_results'.tr(),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final n = _results[i];
                        return Card(
                          child: ListTile(
                            title: Text(n.title.isEmpty
                                ? 'home.new_note'.tr()
                                : n.title),
                            subtitle: Text(
                              n.previewText(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => context.push(
                              '${AppRoutes.noteEditor}/${n.id}',
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
