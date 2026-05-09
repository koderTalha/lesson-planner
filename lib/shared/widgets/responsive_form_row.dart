import 'package:flutter/material.dart';

class ResponsiveFormCell {
  final Widget child;
  final int flex;

  const ResponsiveFormCell(this.child, {this.flex = 1});
}

class ResponsiveFormRow extends StatelessWidget {
  final List<ResponsiveFormCell> cells;
  final double breakpoint;
  final double horizontalGap;
  final double verticalGap;

  const ResponsiveFormRow({
    super.key,
    required this.cells,
    this.breakpoint = 520,
    this.horizontalGap = 12,
    this.verticalGap = 14,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        if (c.maxWidth <= breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < cells.length; i++) ...[
                if (i > 0) SizedBox(height: verticalGap),
                cells[i].child,
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < cells.length; i++) ...[
              if (i > 0) SizedBox(width: horizontalGap),
              Expanded(flex: cells[i].flex, child: cells[i].child),
            ],
          ],
        );
      },
    );
  }
}
