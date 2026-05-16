import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/lesson_pdf_repository.dart';
import '../../../core/storage/saved_lesson_pdf.dart';
import '../../../core/storage/saved_slide_pptx.dart';
import '../../../core/storage/slide_pptx_repository.dart';
import '../../../shared/widgets/widgets.dart';
import '../../shell/bloc/nav_cubit.dart';
import '../bloc/media_cubit.dart';
import '../bloc/media_state.dart';
import 'pdf_preview_screen.dart';
import 'ppt_preview_screen.dart';

class MediaScreen extends StatelessWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => MediaCubit(
        c.read<LessonPdfRepository>(),
        c.read<SlidePptxRepository>(),
      ),
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
                  a.kind != b.kind ||
                  a.pdfItems != b.pdfItems ||
                  a.slideItems != b.slideItems ||
                  a.loading != b.loading ||
                  a.error != b.error,
              builder: (context, state) {
                final loadingEmpty = state.loading &&
                    state.pdfItems.isEmpty &&
                    state.slideItems.isEmpty;
                if (loadingEmpty) {
                  return const _LoadingState();
                }
                if (state.error != null && state.isEmpty) {
                  return _ErrorState(message: state.error!);
                }
                return RefreshIndicator(
                  onRefresh: () => context.read<MediaCubit>().refresh(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: MediaCapsuleSwitch(
                            value: state.kind,
                            onChanged: context.read<MediaCubit>().selectKind,
                          ),
                        ),
                      ),
                      if (state.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(kind: state.kind),
                        )
                      else if (state.kind == MediaLibraryKind.pdf)
                        _PdfListSliver(items: state.pdfItems)
                      else
                        _SlideListSliver(items: state.slideItems),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PdfListSliver extends StatelessWidget {
  final List<SavedLessonPdf> items;

  const _PdfListSliver({required this.items});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      sliver: SliverList.separated(
        itemCount: items.length + 1,
        separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 20 : 12),
        itemBuilder: (context, i) {
          if (i == 0) {
            return AppHeroBanner(
              icon: Icons.picture_as_pdf_rounded,
              title: 'Lesson plans',
              subtitle:
                  'Tap to preview · share or print. ${items.length} ${items.length == 1 ? 'file' : 'files'}.',
            );
          }
          return _PdfCard(item: items[i - 1]);
        },
      ),
    );
  }
}

class _SlideListSliver extends StatelessWidget {
  final List<SavedSlidePptx> items;

  const _SlideListSliver({required this.items});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      sliver: SliverList.separated(
        itemCount: items.length + 1,
        separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 20 : 12),
        itemBuilder: (context, i) {
          if (i == 0) {
            return AppHeroBanner(
              icon: Icons.slideshow_rounded,
              title: 'Slide decks',
              subtitle:
                  'Tap to view · open in PowerPoint or share. ${items.length} ${items.length == 1 ? 'deck' : 'decks'}.',
            );
          }
          return _SlideCard(item: items[i - 1]);
        },
      ),
    );
  }
}

class _PdfCard extends StatelessWidget {
  final SavedLessonPdf item;

  const _PdfCard({required this.item});

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
    if (ok == true) await cubit.deletePdf(item);
  }

  @override
  Widget build(BuildContext context) {
    return _MediaCardShell(
      icon: Icons.picture_as_pdf_rounded,
      title: item.displayTitle,
      subtitle: item.displaySubtitle,
      date: item.readableDate,
      size: item.readableSize,
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
      onShare: () => context.read<MediaCubit>().sharePdf(item),
      onDelete: () => _confirmDelete(context),
    );
  }
}

class _SlideCard extends StatelessWidget {
  final SavedSlidePptx item;

  const _SlideCard({required this.item});

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<MediaCubit>();
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete slides?'),
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
    if (ok == true) await cubit.deleteSlide(item);
  }

  @override
  Widget build(BuildContext context) {
    return _MediaCardShell(
      icon: Icons.slideshow_rounded,
      title: item.displayTitle,
      subtitle: item.displaySubtitle,
      date: item.readableDate,
      size: item.readableSize,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<MediaCubit>(),
              child: PptPreviewScreen(item: item),
            ),
          ),
        );
      },
      onShare: () => context.read<MediaCubit>().shareSlide(item),
      onDelete: () => _confirmDelete(context),
    );
  }
}

class _MediaCardShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String date;
  final String size;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _MediaCardShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.size,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
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
                child: Icon(icon, color: scheme.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
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
                        _MetaChip(icon: Icons.event_outlined, label: date),
                        _MetaChip(icon: Icons.sd_storage_outlined, label: size),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_CardAction>(
                tooltip: 'More',
                icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
                onSelected: (a) async {
                  switch (a) {
                    case _CardAction.share:
                      onShare();
                    case _CardAction.delete:
                      onDelete();
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
  final MediaLibraryKind kind;

  const _EmptyState({required this.kind});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isPdf = kind == MediaLibraryKind.pdf;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPdf ? Icons.auto_stories_rounded : Icons.slideshow_rounded,
              size: 36,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPdf ? 'No lesson plans yet' : 'No slide decks yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPdf
                ? 'Generate a plan in the Lesson tab — it saves here automatically.'
                : 'Generate slides in the Slides tab — they save here automatically.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                context.read<NavCubit>().select(isPdf ? 0 : 2),
            icon: Icon(isPdf ? Icons.add_rounded : Icons.auto_awesome),
            label: Text(isPdf ? 'Create a lesson plan' : 'Generate slides'),
          ),
        ],
      ),
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
