import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_autofill_service/flutter_autofill_service.dart';
import 'package:flutter_secure_screen/flutter_secure_screen.dart';
import 'package:passy/passy_data/password.dart';
import 'package:passy/passy_data/passy_search.dart';
import 'package:passy/screens/remove_account_screen.dart';
import 'package:passy/screens/search_screen.dart';
import 'package:passy/common/common.dart';
import 'package:passy/passy_data/common.dart';
import 'package:passy/passy_data/loaded_account.dart';
import 'package:passy/passy_flutter/passy_flutter.dart';
import 'package:passy/common/assets.dart';
import 'package:passy/screens/splash_screen.dart';

import 'add_account_screen.dart';
import 'common.dart';
import 'edit_password_screen.dart';
import 'global_settings_screen.dart';
import 'main_screen.dart';
import 'log_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> with WidgetsBindingObserver {
  static bool didRun = false;
  Widget? _floatingActionButton;
  String _password = '';
  String _username = data.info.value.lastUsername;
  FloatingActionButton? _bioAuthButton;
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _bioAuth() async {
    if (Platform.isAndroid || Platform.isIOS) {
      if (data.getBioAuthEnabled(_username) ?? false) {
        if (await bioAuth(_username)) {
          Navigator.popUntil(
              context, (route) => route.settings.name == LoginScreen.routeName);
          Navigator.pushReplacementNamed(context, MainScreen.routeName);
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) _bioAuth();
  }

  Widget _buildPasswords(String terms) {
    List<PasswordMeta> _found = PassySearch.searchPasswords(
        passwords: data.loadedAccount!.passwordsMetadata.values, terms: terms);
    List<PwDataset> _dataSets = [];
    return PasswordButtonListView(
      topWidgets: [
        PassyPadding(ThreeWidgetButton(
          left: const Icon(Icons.add_rounded),
          center: Text(
            localizations.addPassword,
            textAlign: TextAlign.center,
          ),
          right: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () =>
              Navigator.pushNamed(context, EditPasswordScreen.routeName),
        )),
      ],
      passwords: _found,
      onPressed: (password) async {
        _found.remove(password);
        _found.insert(0, password);
        int max = _found.length < 5 ? _found.length : 5;
        for (int i = 0; i != max; i++) {
          PasswordMeta _password = _found[i];
          Password? _pass = data.loadedAccount!.getPassword(_password.key);
          if (_pass == null) continue;
          _dataSets.add(PwDataset(
            label: _password.nickname,
            username: _pass.username.isNotEmpty ? _pass.username : _pass.email,
            password: _pass.password,
          ));
        }
        await AutofillService().resultWithDatasets(_dataSets);
        Navigator.pop(context);
      },
      shouldSort: true,
    );
  }

  void login() {
    if (getPassyHash(_password).toString() != data.getPasswordHash(_username)) {
      showSnackBar(
        context,
        message: localizations.incorrectPassword,
        icon:
            const Icon(Icons.lock_rounded, color: PassyTheme.darkContentColor),
      );
      setState(() {
        _password = '';
        _passwordController.text = '';
      });
      return;
    }
    data.info.value.lastUsername = _username;
    Navigator.pushNamed(context, SplashScreen.routeName);
    data.info.save().whenComplete(() async {
      try {
        LoadedAccount _account = await data.loadAccount(
            data.info.value.lastUsername, getPassyEncrypter(_password));
        Navigator.pop(context);
        if (isAutofill) {
          Navigator.pushNamed(
            context,
            SearchScreen.routeName,
            arguments: SearchScreenArgs(
              builder: _buildPasswords,
              isAutofill: true,
            ),
          );
          return;
        }
        if (Platform.isAndroid) {
          FlutterSecureScreen.singleton
              .setAndroidScreenSecure(_account.protectScreen);
        }
        Navigator.pushReplacementNamed(context, MainScreen.routeName);
      } catch (e, s) {
        showSnackBar(
          context,
          message: localizations.couldNotLogin,
          icon: const Icon(Icons.lock_rounded,
              color: PassyTheme.darkContentColor),
          action: SnackBarAction(
            label: localizations.details,
            onPressed: () => Navigator.pushNamed(context, LogScreen.routeName,
                arguments: e.toString() + '\n' + s.toString()),
          ),
        );
      }
    });
  }

  void updateBioAuthButton() {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (isAutofill) return;
    if (data.getBioAuthEnabled(_username) == true) {
      _bioAuthButton = FloatingActionButton(
        onPressed: () => _bioAuth(),
        child: const Icon(
          Icons.fingerprint_rounded,
        ),
        tooltip: localizations.authenticate,
        heroTag: null,
      );
      return;
    }
    _bioAuthButton = null;
  }

  @override
  void initState() {
    super.initState();
    data.refreshAccounts();
    if (!isAutofill) {
      if (Platform.isAndroid) {
        FlutterSecureScreen.singleton.setAndroidScreenSecure(true);
      }
      _floatingActionButton =
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        FloatingActionButton(
          child: const Icon(Icons.settings_rounded),
          tooltip: localizations.settings,
          heroTag: null,
          onPressed: () =>
              Navigator.pushNamed(context, GlobalSettingsScreen.routeName),
        ),
        if (!Platform.isAndroid && !Platform.isIOS)
          Padding(
            padding: EdgeInsets.only(left: PassyTheme.passyPadding.left),
            child: FloatingActionButton(
              child: const Icon(Icons.extension_rounded),
              tooltip: localizations.passyBrowserExtension,
              heroTag: null,
              onPressed: () => openUrl(
                  'https://github.com/GlitterWare/Passy-Browser-Extension/blob/main/DOWNLOADS.md'),
            ),
          ),
      ]);
    }
    WidgetsBinding.instance.addObserver(this);
    if (didRun) return;
    didRun = true;
    _bioAuth();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    updateBioAuthButton();
    final List<DropdownMenuItem<String>> usernames = data.usernames
        .map<DropdownMenuItem<String>>((_username) => DropdownMenuItem(
              child: Row(children: [
                Expanded(child: Text(_username)),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      RemoveAccountScreen.routeName,
                      arguments: _username,
                    );
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: localizations.remove,
                  splashRadius: PassyTheme.appBarButtonSplashRadius,
                  padding: PassyTheme.appBarButtonPadding,
                ),
              ]),
              value: _username,
            ))
        .toList();

    return Scaffold(
      floatingActionButton: _floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                const Spacer(flex: 2),
                logo60Purple,
                const Spacer(),
                Expanded(
                  child: Row(
                    children: [
                      const Spacer(),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                if (!isAutofill)
                                  FloatingActionButton(
                                    onPressed: () =>
                                        Navigator.pushReplacementNamed(context,
                                            AddAccountScreen.routeName),
                                    child: const Icon(Icons.add_rounded),
                                    tooltip: localizations.addAccount,
                                    heroTag: 'addAccountBtn',
                                  ),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(30)),
                                    value: _username,
                                    items: usernames,
                                    selectedItemBuilder: (context) {
                                      return usernames.map<Widget>((item) {
                                        return Text(item.value!);
                                      }).toList();
                                    },
                                    onChanged: (a) {
                                      setState(() => _username = a!);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    onChanged: (a) =>
                                        setState(() => _password = a),
                                    onSubmitted: (s) => login(),
                                    decoration: InputDecoration(
                                      hintText: localizations.password,
                                    ),
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(32),
                                    ],
                                    autofocus: true,
                                  ),
                                ),
                                FloatingActionButton(
                                  onPressed: () => login(),
                                  child: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                  ),
                                  tooltip: localizations.logIn,
                                  heroTag: null,
                                ),
                                if (_bioAuthButton != null) _bioAuthButton!,
                              ],
                            ),
                          ],
                        ),
                        flex: 10,
                      ),
                      const Spacer(),
                    ],
                  ),
                  flex: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
