import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/lesson_pdf_repository.dart';
import '../../../core/storage/saved_lesson_pdf.dart';
import '../../../shared/widgets/widgets.dart';
import '../../shell/bloc/nav_cubit.dart';
import '../bloc/media_cubit.dart';
import '../bloc/media_state.dart';
import 'pdf_preview_screen.dart';

class MediaScreen extends StatelessWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => MediaCubit(c.read<LessonPdfRepository>()),
      child: const _MediaView(),
    );
  }
}

class _MediaView extends StatelessWidget {
  const _MediaView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Media',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<MediaCubit>().refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: BlocBuilder<MediaCubit, MediaState>(
              buildWhen: (a, b) =>
                  a.items != b.items ||
                  a.loading != b.loading ||
                  a.error != b.error,
              builder: (context, state) {
                if (state.loading && state.items.isEmpty) {
                  return const _LoadingState();
                }
                if (state.error != null && state.items.isEmpty) {
                  return _ErrorState(message: state.error!);
                }
                return RefreshIndicator(
                  onRefresh: () => context.read<MediaCubit>().refresh(),
                  child: state.items.isEmpty
                      ? const _EmptyState()
                      : _MediaList(items: state.items),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaList extends StatelessWidget {
  final List<SavedLessonPdf> items;

  const _MediaList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: items.length + 1,
      separatorBuilder: (_, i) =>
          SizedBox(height: i == 0 ? 24 : 12),
      itemBuilder: (context, i) {
        if (i == 0) {
          return AppHeroBanner(
            icon: Icons.perm_media_rounded,
            title: 'Saved lesson plans',
            subtitle:
                'Tap a card to preview, share or print. ${items.length} ${items.length == 1 ? 'plan' : 'plans'} saved.',
          );
        }
        return _MediaCard(item: items[i - 1]);
      },
    );
  }
}

class _MediaCard extends StatelessWidget {
  final SavedLessonPdf item;

  const _MediaCard({required this.item});

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<MediaCubit>();
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete lesson plan?'),
        content: Text(
          'This will permanently remove “${item.displayTitle}” from your device.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.delete(item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<MediaCubit>(),
                child: PdfPreviewScreen(item: item),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: scheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.displaySubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _MetaChip(
                          icon: Icons.event_outlined,
                          label: item.readableDate,
                        ),
                        _MetaChip(
                          icon: Icons.sd_storage_outlined,
                          label: item.readableSize,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<_CardAction>(
                tooltip: 'More',
                icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
                onSelected: (a) async {
                  switch (a) {
                    case _CardAction.share:
                      await context.read<MediaCubit>().share(item);
                    case _CardAction.delete:
                      await _confirmDelete(context);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _CardAction.share,
                    child: ListTile(
                      leading: Icon(Icons.ios_share_rounded),
                      title: Text('Share'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: _CardAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded),
                      title: Text('Delete'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _CardAction { share, delete }

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        const AppHeroBanner(
          icon: Icons.perm_media_rounded,
          title: 'No lesson plans yet',
          subtitle:
              'Generate one in the Lesson tab — it will be saved here automatically.',
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 36,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your library is empty',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Saved PDFs will appear here, sorted by newest first.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.read<NavCubit>().select(0),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create a lesson plan'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      children: [
        AppInlineError(message),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.read<MediaCubit>().refresh(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ],
    );
  }
}
