import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';
import 'package:passy/common/common.dart';
import 'package:passy/common/theme.dart';
import 'package:passy/passy_data/loaded_account.dart';
import 'package:passy/passy_data/password.dart';
import 'package:passy/passy_data/tfa.dart';
import 'package:passy/screens/password_screen.dart';
import 'package:passy/screens/splash_screen.dart';

import 'main_screen.dart';
import 'passwords_screen.dart';

class EditPasswordScreen extends StatefulWidget {
  const EditPasswordScreen({Key? key}) : super(key: key);

  static const routeName = '${PasswordsScreen.routeName}/editPassword';

  @override
  State<StatefulWidget> createState() => _EditPasswordScreen();
}

class _EditPasswordScreen extends State<EditPasswordScreen> {
  final LoadedAccount _account = data.loadedAccount!;

  @override
  Widget build(BuildContext context) {
    Object? _args = ModalRoute.of(context)!.settings.arguments;
    bool _isNew = _args == null;
    final Password _password = _isNew ? Password() : _args as Password;
    final TFA _tfa = _password.tfa ?? TFA();

    _args = null;

    return Scaffold(
      appBar: getEditScreenAppBar(
        context,
        title: 'Password',
        isNew: _isNew,
        onSave: () {
          _tfa.secret != '' ? _password.tfa = _tfa : _password.tfa = null;
          _account.setPassword(_password);
          Navigator.pushNamed(context, SplashScreen.routeName);
          _account.save().whenComplete(() {
            Navigator.popUntil(
                context, (r) => r.settings.name == MainScreen.routeName);
            Navigator.pushNamed(context, PasswordsScreen.routeName);
            Navigator.pushNamed(context, PasswordScreen.routeName,
                arguments: _password);
          });
        },
      ),
      body: ListView(children: [
        Padding(
          padding: entryPadding,
          child: TextFormField(
            controller: TextEditingController(text: _password.nickname),
            decoration: const InputDecoration(
              labelText: 'Nickname',
            ),
            onChanged: (value) => _password.nickname = value,
          ),
        ),
        Padding(
          padding: entryPadding,
          child: TextFormField(
            controller: TextEditingController(text: _password.username),
            decoration: const InputDecoration(labelText: 'Username'),
            onChanged: (value) => _password.username = value,
          ),
        ),
        Padding(
          padding: entryPadding,
          child: TextFormField(
            controller: TextEditingController(text: _password.email),
            decoration: const InputDecoration(labelText: 'Email'),
            onChanged: (value) => _password.email = value,
          ),
        ),
        Padding(
          padding: entryPadding,
          child: TextFormField(
            controller: TextEditingController(text: _password.password),
            decoration: const InputDecoration(labelText: 'Password'),
            onChanged: (value) => _password.password = value,
          ),
        ),
        Padding(
          padding: entryPadding,
          child: TextFormField(
            controller:
                TextEditingController(text: _tfa.secret.replaceFirst('=', '')),
            decoration: const InputDecoration(labelText: '2FA Secret'),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'([a-z]|[A-Z]|[2-7])')),
              TextInputFormatter.withFunction((oldValue, newValue) =>
                  TextEditingValue(
                      text: newValue.text.toUpperCase(),
                      selection: newValue.selection)),
            ],
            onChanged: (value) {
              if (value.length.isOdd) value += '=';
              _tfa.secret = value;
            },
          ),
        ),
        Padding(
          padding: entryPadding,
          child: TextFormField(
            controller: TextEditingController(text: _tfa.length.toString()),
            decoration: const InputDecoration(labelText: '2FA Length'),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => _tfa.length = int.parse(value),
          ),
        ),
        Padding(
          padding: entryPadding,
          child: TextFormField(
            controller: TextEditingController(text: _tfa.interval.toString()),
            decoration: const InputDecoration(labelText: '2FA Interval'),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => _tfa.interval = int.parse(value),
          ),
        ),
        Padding(
          padding: entryPadding,
          child: DropdownButtonFormField(
            items: [
              DropdownMenuItem(
                child: Text(Algorithm.SHA1.name),
                value: Algorithm.SHA1,
              ),
              DropdownMenuItem(
                child: Text(Algorithm.SHA256.name),
                value: Algorithm.SHA256,
              ),
              DropdownMenuItem(
                child: Text(Algorithm.SHA512.name),
                value: Algorithm.SHA512,
              ),
            ],
            value: _tfa.algorithm,
            decoration: const InputDecoration(labelText: '2FA Algorithm'),
            onChanged: (value) => _tfa.algorithm = value as Algorithm,
          ),
        ),
        Padding(
          padding: entryPadding,
          child: TextFormField(
            controller: TextEditingController(text: _password.website),
            decoration: const InputDecoration(labelText: 'Website'),
            onChanged: (value) => _password.website = value,
          ),
        ),
        Padding(
          padding: entryPadding,
          child: TextFormField(
            controller: TextEditingController(text: _password.additionalInfo),
            decoration: const InputDecoration(labelText: 'Additional Info'),
            onChanged: (value) => _password.additionalInfo = value,
          ),
        ),
      ]),
    );
  }
}
