import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:passy/passy_data/custom_field.dart';
import 'package:passy/passy_flutter/common/common.dart';
import 'package:passy/passy_flutter/passy_flutter.dart';

class CustomFieldEditorListView extends StatefulWidget {
  final List<CustomField> customFields;
  final bool shouldSort;
  final EdgeInsetsGeometry padding;
  final ColorScheme? datePickerColorScheme;
  final Future<CustomField?> Function() buildCustomField;

  const CustomFieldEditorListView({
    Key? key,
    required this.customFields,
    this.shouldSort = false,
    this.padding = EdgeInsets.zero,
    this.datePickerColorScheme = PassyTheme.datePickerColorScheme,
    required this.buildCustomField,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CustomFieldEditorListView();
}

class _CustomFieldEditorListView extends State<CustomFieldEditorListView> {
  @override
  void initState() {
    super.initState();
    if (widget.shouldSort) PassySort.sortCustomFields(widget.customFields);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PassyPadding(ThreeWidgetButton(
          left: const Padding(
            padding: EdgeInsets.only(right: 30),
            child: Icon(Icons.add_rounded),
          ),
          center: const Text('Add custom field'),
          onPressed: () {
            widget.buildCustomField().then((value) {
              if (value != null) {
                setState(() {
                  widget.customFields.add(value);
                  PassySort.sortCustomFields(widget.customFields);
                });
              }
            });
          },
        )),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: widget.customFields.length,
          itemBuilder: (context, index) {
            List<TextInputFormatter>? _inputFormatters;
            CustomField _field = widget.customFields[index];
            List<Widget> _widgets = [];
            switch (_field.fieldType) {
              case (FieldType.number):
                _inputFormatters = [FilteringTextInputFormatter.digitsOnly];
                break;
              case (FieldType.date):
                _widgets.add(
                  FloatingActionButton(
                    heroTag: null,
                    onPressed: () => showPassyDatePicker(
                      context: context,
                      date: _field.value == ''
                          ? DateTime.now()
                          : stringToDate(_field.value),
                    ).then(
                      (value) {
                        if (value == null) return;
                        setState(() => _field.value = dateToString(value));
                      },
                    ),
                    child: const Icon(Icons.date_range),
                  ),
                );
                break;
              default:
                break;
            }
            _widgets.insert(
              0,
              Flexible(
                child: TextFormField(
                  inputFormatters: _inputFormatters,
                  initialValue: _field.value,
                  decoration: InputDecoration(
                    labelText: _field.title,
                  ),
                  onChanged: (value) => _field.value = value,
                ),
              ),
            );
            _widgets.add(
              FloatingActionButton(
                heroTag: null,
                onPressed: () =>
                    setState(() => widget.customFields.removeAt(index)),
                child: const Icon(Icons.remove_rounded),
              ),
            );
            return Padding(
              padding: PassyTheme.passyPadding,
              child: Row(
                key: UniqueKey(),
                children: _widgets,
              ),
            );
          },
        ),
      ],
    );
  }
}
