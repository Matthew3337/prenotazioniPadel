import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/autenticazione/authBloc.dart';
import 'package:thepadel/bloc/autenticazione/authState.dart';
import 'package:thepadel/bloc/autenticazione/authevent.dart';
import 'package:thepadel/core/di/depInjection.dart';

import 'home.dart';
import 'registrazione.dart';
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
      child: const Scaffold(
        backgroundColor: Color(0xFFF7F8FC),
        body: _LoginForm(),
      ),
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
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;
    // Dimensione massima del contenuto sui dispositivi grandi
    final contentWidth = width > 500 ? 420.0 : width * 0.88;
    // Dimensione adattiva del logo
    final logoSize = width * 0.38 > 180 ? 180.0 : width * 0.38;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.06,
            vertical: height * 0.025,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: contentWidth,
            ),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is LoginSuccess) {
                  Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                  builder: (BuildContext context) => const HomePage(),
                ));
                }
                if (state is AuthErrore) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.messaggio),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.symmetric(
                        horizontal: width * 0.05,
                        vertical: height * 0.02,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LOGO
                    SizedBox(
                      height: height * 0.04,
                    ),
                    Center(
                      child: Container(
                        width: logoSize,
                        height: logoSize,
                        padding: EdgeInsets.all(width * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            "assets/icon/logoHome.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: height * 0.035,
                    ),
                    // TITOLO
                    Text(
                      "Bentornato!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: width * 0.075,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E2432),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(
                      height: height * 0.008,
                    ),
                    Text(
                      "Accedi al tuo account per continuare",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: width * 0.038,
                        color: const Color(0xFF7A8190),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(
                      height: height * 0.045,
                    ),
                    // TELEFONO
                    Text(
                      "Numero di telefono",
                      style: TextStyle(
                        fontSize: width * 0.035,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF353B48),
                      ),
                    ),
                    SizedBox(
                      height: height * 0.01,
                    ),
                    TextField(
                      controller: _telefonoController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        fontSize: width * 0.04,
                        color: const Color(0xFF252A35),
                      ),
                      decoration: InputDecoration(
                        hintText: "Inserisci il tuo numero",
                        hintStyle: const TextStyle(
                          color: Color(0xFFA0A5AF),
                        ),
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: Color(0xFF3F5DA8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: width * 0.045,
                          vertical: height * 0.021,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE3E6ED),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF3F5DA8),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: height * 0.025,
                    ),
                    // PASSWORD
                    Text(
                      "Password",
                      style: TextStyle(
                        fontSize: width * 0.035,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF353B48),
                      ),
                    ),
                    SizedBox(
                      height: height * 0.01,
                    ),
                    TextField(
                      controller: _passwordController,
                      enabled: !isLoading,
                      obscureText: _nascondiPassword,
                      style: TextStyle(
                        fontSize: width * 0.04,
                        color: const Color(0xFF252A35),
                      ),
                      decoration: InputDecoration(
                        hintText: "Inserisci la password",
                        hintStyle: const TextStyle(
                          color: Color(0xFFA0A5AF),
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF3F5DA8),
                        ),
                        suffixIcon: IconButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _nascondiPassword =
                                        !_nascondiPassword;
                                  });
                                },
                          icon: Icon(
                            _nascondiPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF8C93A0),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: width * 0.045,
                          vertical: height * 0.021,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE3E6ED),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF3F5DA8),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: height * 0.04,
                    ),
                    // BOTTONE LOGIN
                    SizedBox(
                      height: height * 0.065,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                context.read<AuthBloc>().add(
                                  LoginRichiesto(
                                    telefono:
                                        _telefonoController.text,
                                    password:
                                        _passwordController.text,
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF3F5DA8),
                          disabledBackgroundColor:
                              const Color(0xFF9AA8C8),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor:
                              const Color(0xFF3F5DA8).withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: width * 0.055,
                                height: width * 0.055,
                                child:
                                    const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                "ACCEDI",
                                style: TextStyle(
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(
                      height: height * 0.02,
                    ),
                    // LINK REGISTRAZIONE
                    Center(
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext context) =>
                                        const RegistrazionePage(),
                                  ),
                                );
                              },
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: width * 0.036,
                              color: const Color(0xFF7A8190),
                            ),
                            children: const [
                              TextSpan(text: "Non hai un account? "),
                              TextSpan(
                                text: "Registrati",
                                style: TextStyle(
                                  color: Color(0xFF3F5DA8),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: height * 0.015,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}