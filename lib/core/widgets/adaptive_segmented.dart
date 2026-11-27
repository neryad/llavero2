import 'package:flutter/material.dart';

/// Selector de opciones que no rompe con fuentes grandes ni pantallas estrechas.
///
/// Con escala normal usa un [SegmentedButton] a ancho completo con etiquetas
/// de una sola línea que se encogen (`FittedBox`). Con escala al 200 % pasa a
/// una lista vertical de opciones tipo radio.
class AdaptiveSegmented<T> extends StatelessWidget {
  const AdaptiveSegmented({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  }) : assert(values.length == labels.length);

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  static bool useVertical(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(16) / 16 >= 2;

  @override
  Widget build(BuildContext context) {
    if (useVertical(context)) {
      return RadioGroup<T>(
        groupValue: selected,
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        child: Column(
          children: <Widget>[
            for (var i = 0; i < values.length; i++)
              RadioListTile<T>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                value: values[i],
              ),
          ],
        ),
      );
    }

    return SegmentedButton<T>(
      expandedInsets: EdgeInsets.zero,
      segments: <ButtonSegment<T>>[
        for (var i = 0; i < values.length; i++)
          ButtonSegment<T>(
            value: values[i],
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(labels[i], maxLines: 1),
            ),
          ),
      ],
      selected: <T>{selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
