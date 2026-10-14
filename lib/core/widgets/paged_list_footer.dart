import 'package:flutter/material.dart';

import '../paged_search.dart';
import '../theme/app_theme.dart';

/// Ultimo elemento di una lista paginata: va aggiunto solo se
/// `results.hasMore` o `results.loadMoreFailed`.
///
/// Quando viene costruito chiede la pagina successiva. Una `ListView` costruisce
/// gli elementi poco prima che entrino nello schermo, quindi il caricamento
/// parte appena l'utente si avvicina al fondo, senza `ScrollController`, e
/// anche quando la prima pagina non riempie lo schermo.
class PagedListFooter extends StatefulWidget {
  final PagedResults<Object?> results;
  final VoidCallback onLoadMore;

  const PagedListFooter({
    super.key,
    required this.results,
    required this.onLoadMore,
  });

  @override
  State<PagedListFooter> createState() => _PagedListFooterState();
}

class _PagedListFooterState extends State<PagedListFooter> {
  @override
  void initState() {
    super.initState();
    _requestIfIdle();
  }

  @override
  void didUpdateWidget(PagedListFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _requestIfIdle();
  }

  void _requestIfIdle() {
    final r = widget.results;
    if (!r.hasMore || r.isLoadingMore || r.loadMoreFailed) return;
    // Non durante il build: loadMore aggiorna subito lo stato del provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLoadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const Text(
              'Impossibile caricare altri risultati',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            TextButton(
              onPressed: widget.onLoadMore,
              child: const Text(
                'Riprova',
                style: TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.accent),
        ),
      ),
    );
  }
}
