import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/bloc/autenticazione/authBloc.dart';
import 'package:thepadel/bloc/autenticazione/authState.dart';
import 'package:thepadel/bloc/autenticazione/authevent.dart';
import 'package:thepadel/core/di/depInjection.dart';

import 'home.dart';
import 'homeAdmin.dart';
import 'registrazione.dart';
import 'stileApp.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const Scaffold(backgroundColor: Colors.white, body: _LoginForm()),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _nascondiPassword = true;

  @override
  void dispose() {
    _telefonoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    // il margine sotto e' piu' grande di quello sopra: il form centrato
    // risale un po' e il logo sta piu' in alto
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is LoginSuccess) {
                  // l'admin ha una home tutta sua
                  final bool isAdmin =
                      sl<SharedPreferences>().getBool('isAdmin') == true;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder:
                          (BuildContext context) =>
                              isAdmin
                                  ? const HomeAdminPage()
                                  : const HomePage(),
                    ),
                  );
                }
              },
              builder: (context, state) {
                final bool isLoading = state is AuthLoading;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: _LogoRitagliato()),
                    const SizedBox(height: 28),
                    if (state is AuthErrore) ...[
                      RiquadroMessaggio(testo: state.messaggio),
                      const SizedBox(height: 14),
                    ],
                    _buildTelefono(r, isLoading),
                    const SizedBox(height: 14),
                    _buildPassword(r, isLoading),
                    const SizedBox(height: 18),
                    _buildBottone(context, r, isLoading),
                    if (!isLoading) ...[
                      const SizedBox(height: 14),
                      _buildVaiARegistrazione(context, r),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // il nome del campo sta dentro il campo stesso, in grigio
  InputDecoration _decorazione(
    Responsive r,
    String suggerimento,
    bool isLoading, {
    Widget? suffisso,
  }) {
    OutlineInputBorder bordo(Color colore, double spessore) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colore, width: spessore),
      );
    }

    return InputDecoration(
      hintText: suggerimento,
      hintStyle: stileTesto(r, base: 16, colore: Colori.grigio),
      filled: true,
      fillColor: isLoading ? Colori.sfondo : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      suffixIcon: suffisso,
      enabledBorder: bordo(Colori.grigio, 1),
      disabledBorder: bordo(Colori.bordo, 1),
      focusedBorder: bordo(Colori.azzurro, 2),
    );
  }

  Widget _buildTelefono(Responsive r, bool isLoading) {
    return TextField(
      controller: _telefonoController,
      enabled: !isLoading,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumber],
      style: stileTesto(
        r,
        base: 16,
        colore: isLoading ? Colori.testoSecondario : Colori.testo,
      ),
      decoration: _decorazione(r, 'Telefono', isLoading),
    );
  }

  Widget _buildPassword(Responsive r, bool isLoading) {
    Widget? mostra;
    if (!isLoading) {
      mostra = IconButton(
        tooltip: _nascondiPassword ? 'Mostra password' : 'Nascondi password',
        icon: Icon(
          _nascondiPassword ? Icons.visibility : Icons.visibility_off,
          color: Colori.grigio,
        ),
        onPressed: () {
          setState(() {
            _nascondiPassword = !_nascondiPassword;
          });
        },
      );
    }

    return TextField(
      controller: _passwordController,
      enabled: !isLoading,
      obscureText: _nascondiPassword,
      autofillHints: const [AutofillHints.password],
      style: stileTesto(
        r,
        base: 16,
        colore: isLoading ? Colori.testoSecondario : Colori.testo,
      ),
      decoration: _decorazione(r, 'Password', isLoading, suffisso: mostra),
    );
  }

  Widget _buildBottone(BuildContext context, Responsive r, bool isLoading) {
    return BottonePieno(
      testo: isLoading ? 'Accesso in corso…' : 'Accedi',
      altezza: 52,
      baseFont: 16,
      sfondo: Colori.bluAcceso,
      onPressed:
          isLoading
              ? null
              : () {
                context.read<AuthBloc>().add(
                  LoginRichiesto(
                    telefono: _telefonoController.text,
                    password: _passwordController.text,
                  ),
                );
              },
    );
  }

  Widget _buildVaiARegistrazione(BuildContext context, Responsive r) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Non hai un account? ', style: stileSecondario(r)),
        LinkTesto(
          testo: 'Registrati',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const RegistrazionePage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Il PNG del logo e' quadrato ma il disegno occupa solo una striscia centrale:
// lo ingrandisco e ne mostro quella parte, con le misure del prototipo.
class _LogoRitagliato extends StatelessWidget {
  const _LogoRitagliato();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'the Padel',
      child: ClipRect(
        child: SizedBox(
          width: 210,
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -110,
                top: -179,
                width: 430,
                height: 430,
                child: Image.asset(
                  'assets/icon/logoHome.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
