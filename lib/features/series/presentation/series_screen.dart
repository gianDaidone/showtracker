import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/tables/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/series_providers.dart';
import 'widgets/show_card.dart';

class SeriesListScreen extends ConsumerStatefulWidget {
  const SeriesListScreen({super.key});

  @override
  ConsumerState<SeriesListScreen> createState() => _SeriesListScreenState();
}

class _SeriesListScreenState extends ConsumerState<SeriesListScreen> {
  bool _isSearching = false;
  final _controller = TextEditingController();
  String _query = '';
  MediaStatus? _selectedStatus;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _stopSearch() => setState(() {
        _isSearching = false;
        _query = '';
        _controller.clear();
      });

  @override
  Widget build(BuildContext context) {
    final showsAsync = ref.watch(trackedShowsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: _isSearching
            ? TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                cursorColor: AppColors.accent,
                decoration: const InputDecoration(
                  hintText: 'Filtra le tue serie…',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              )
            : const Text(
                'Le mie serie',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
              tooltip: 'Annulla',
              onPressed: _stopSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.textPrimary),
              tooltip: 'Filtra serie',
              onPressed: _startSearch,
            ),
        ],
      ),
      body: showsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Errore:\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
        data: (shows) {
          if (shows.isEmpty) return const _EmptyState();

          var filtered = shows;
          if (_selectedStatus != null) {
            filtered = filtered.where((s) => s.status == _selectedStatus).toList();
          }
          if (_query.isNotEmpty) {
            filtered = filtered
                .where((s) =>
                    s.title.toLowerCase().contains(_query.toLowerCase()))
                .toList();
          }

          final list = filtered.isEmpty
              ? _NoResults(query: _query)
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => ShowCard(
                    key: ValueKey(filtered[i].id),
                    show: filtered[i],
                  ),
                );

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Tutti',
                      isSelected: _selectedStatus == null,
                      onTap: () => setState(() => _selectedStatus = null),
                    ),
                    ...MediaStatus.values.map((status) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: status.label,
                            isSelected: _selectedStatus == status,
                            onTap: () => setState(() => _selectedStatus = status),
                          ),
                        )),
                  ],
                ),
              ),
              Expanded(child: list),
            ],
          );
        },
      ),
    );
  }
}

// ── Nessun risultato per il filtro ────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty ? 'Nessuna serie trovata\nper "$query"' : 'Nessuna serie in questo stato',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lista vuota ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tv_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Nessuna serie aggiunta',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Usa il tab Cerca per trovare\nuna serie e aggiungerla.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/search?filter=series'),
              icon: const Icon(Icons.search),
              label: const Text('Cerca una serie'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.divider,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
