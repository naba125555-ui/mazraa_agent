import 'package:flutter/material.dart';

import '../../domain/models.dart';
import 'scope.dart';
import 'widgets.dart';

class PagedRecords extends StatefulWidget {
  const PagedRecords({
    super.key,
    this.load,
    this.loadPage,
    required this.itemBuilder,
    this.header = const [],
    this.pageSize = 50,
    this.include,
    this.emptyText,
  }) : assert((load == null) != (loadPage == null));

  final Future<List<Json>> Function(int afterId)? load;
  final Future<RecordPage> Function(int afterId)? loadPage;
  final Widget Function(Json row) itemBuilder;
  final List<Widget> header;
  final int pageSize;
  final bool Function(Json row)? include;
  final String? emptyText;

  @override
  State<PagedRecords> createState() => _PagedRecordsState();
}

class _PagedRecordsState extends State<PagedRecords> {
  final records = <Json>[];
  int cursor = 0;
  int generation = 0;
  bool loading = false;
  bool hasMore = true;
  Object? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  // Observe list scrolls rather than attaching an independent controller.
  // This lets NestedScrollView coordinate the pinned/floating SliverAppBar
  // with pagination and keeps infinite-scroll behavior unchanged.
  void onScroll(ScrollMetrics metrics) {
    if (metrics.extentAfter < 420 && error == null && !loading && hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) load();
      });
    }
  }

  Future<void> reload() async {
    generation++;
    setState(() {
      records.clear();
      cursor = 0;
      hasMore = true;
      loading = false;
      error = null;
    });
    await load();
  }

  Future<void> load() async {
    if (loading || !hasMore) return;
    final request = generation;
    final after = cursor;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final loadPage = widget.loadPage;
      final response = loadPage == null ? null : await loadPage(after);
      final page = response?.items ?? await widget.load!(after);
      if (!mounted || generation != request) return;
      setState(() {
        if (response != null) {
          final known = records.map((row) => numId(row['id'])).toSet();
          for (final row in page) {
            if (known.add(numId(row['id'])) && (widget.include?.call(row) ?? true)) {
              records.add(row);
            }
          }
          final next = response.nextAfterId;
          hasMore = next != null && next > after;
          if (hasMore) cursor = next!;
        } else {
          for (final row in page) {
            final id = numId(row['id']);
            if (id <= cursor) continue;
            cursor = id;
            if (widget.include?.call(row) ?? true) records.add(row);
          }
          hasMore = page.length >= widget.pageSize && cursor > after;
        }
        loading = false;
      });
    } catch (failure) {
      if (!mounted || generation != request) return;
      setState(() {
        error = failure;
        loading = false;
      });
    }
  }

  Widget footer(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final failure = error;
    if (failure != null) {
      return Empty(
        text: failureText(context, failure),
        icon: Icons.cloud_off_outlined,
        action: OutlinedButton(
          onPressed: load,
          child: Text(context.tr('إعادة المحاولة', 'Retry')),
        ),
      );
    }
    if (hasMore) {
      return Center(child: TextButton(
        onPressed: load,
        child: Text(context.tr('عرض المزيد', 'Load more')),
      ));
    }
    return records.isEmpty ? Empty(text: widget.emptyText) : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: reload,
    child: NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth == 0 && notification is ScrollUpdateNotification) {
          onScroll(notification.metrics);
        }
        return false;
      },
      child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 124),
      itemCount: widget.header.length + records.length + 1,
      itemBuilder: (context, index) {
        if (index < widget.header.length) return widget.header[index];
        final offset = index - widget.header.length;
        return offset < records.length ? widget.itemBuilder(records[offset]) : footer(context);
      },
      ),
    ),
  );
}
