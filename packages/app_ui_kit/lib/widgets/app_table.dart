import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:flutter/material.dart";

const _cellPadding = 7.0;
const _headerPadding = 6.0;
const _columnGap = 8.0;

/// Simple data table: optional muted [header], then [rows] split by
/// hairlines. The first column is left-aligned, the rest right-aligned.
/// [boldLastRow] marks a total line.
class AppTable extends StatelessWidget {
  /// Creates the table.
  const AppTable({
    required this.rows,
    super.key,
    this.header,
    this.boldLastRow = false,
    this.columnWidths = const {0: FlexColumnWidth(2)},
  });

  /// Column titles.
  final List<String>? header;

  /// Cells by row.
  final List<List<String>> rows;

  /// Bold the last row.
  final bool boldLastRow;

  /// Width of each column by index; the rest share what is left equally.
  /// Use [IntrinsicColumnWidth] to keep a column's text on one line.
  final Map<int, TableColumnWidth> columnWidths;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      color: colors.textMuted,
      fontWeight: FontWeight.w500,
    );
    final cellStyle = theme.textTheme.bodySmall?.copyWith(
      color: colors.textStrong,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget cell(String text, int column, TextStyle? style) => Padding(
      padding: EdgeInsets.only(left: column == 0 ? 0 : _columnGap),
      child: Text(
        text,
        textAlign: column == 0 ? TextAlign.left : TextAlign.right,
        style: style,
      ),
    );
    final titles = header;
    return Table(
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        if (titles != null)
          TableRow(
            children: [
              for (var c = 0; c < titles.length; c++)
                Padding(
                  padding: const EdgeInsets.only(bottom: _headerPadding),
                  child: cell(titles[c], c, headerStyle),
                ),
            ],
          ),
        for (var r = 0; r < rows.length; r++)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.line)),
            ),
            children: [
              for (var c = 0; c < rows[r].length; c++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: _cellPadding),
                  child: cell(
                    rows[r][c],
                    c,
                    boldLastRow && r == rows.length - 1
                        ? cellStyle?.copyWith(fontWeight: FontWeight.w600)
                        : cellStyle,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
