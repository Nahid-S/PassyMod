import 'package:flutter/material.dart';
import 'package:passy/passy_data/passy_data.dart';
import 'package:passy/widgets/back_button.dart';
import 'package:universal_io/io.dart';

late PassyData data;

final bool cameraSupported = Platform.isAndroid || Platform.isIOS;

AppBar getEditScreenAppBar(
  BuildContext context, {
  required String title,
  required void Function()? onSave,
  bool isNew = false,
}) =>
    AppBar(
      leading: PassyBackButton(onPressed: () => Navigator.pop(context)),
      title: isNew
          ? Center(child: Text('Add $title'))
          : Center(child: Text('Edit $title')),
      actions: [
        IconButton(
          onPressed: onSave,
          icon: isNew
              ? const Icon(Icons.add_rounded)
              : const Icon(Icons.check_rounded),
        ),
      ],
    );
