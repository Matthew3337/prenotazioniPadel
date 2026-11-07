import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/autenticazione/authBloc.dart';
import 'package:thepadel/bloc/autenticazione/authState.dart';
import 'package:thepadel/bloc/autenticazione/authevent.dart';
import 'package:thepadel/core/di/depInjection.dart';

import 'barraNavigazione.dart';
import 'login.dart';
import 'stileApp.dart';

// "Esci" in fondo alle due home: chiede conferma e poi fa il logout
class BottoneEsci extends StatelessWidget {
  const BottoneEsci({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LinkTesto(
        testo: 'Esci',
        peso: FontWeight.w600,
        colore: Colori.testoSecondario,
        onPressed: () {
          showDialog<void>(
            context: context,
            barrierColor: Colori.testo.withValues(alpha: 0.55),
            builder: (_) => const _DialogEsci(),
          );
        },
      ),
    );
  }
}

// il bloc vive dentro il dialog: serve solo per il tempo del logout
class _DialogEsci extends StatelessWidget {
  const _DialogEsci();

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>(),
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                // toglie tutte le pagine: con il tasto indietro non si deve
                // poter tornare a una home senza piu' il login
                if (state is LogoutSuccess) {
                  tornaAllaVoce(context, const LoginPage());
                }
              },
              builder: (context, state) {
                final bool isLoading = state is AuthLoading;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Uscire dall\'app?', style: stileNumero(r, 22)),
                    const SizedBox(height: 8),
                    Text(
                      'Per rientrare dovrai accedere di nuovo.',
                      style: stileSecondario(r),
                    ),
                    if (state is AuthErrore) ...[
                      const SizedBox(height: 12),
                      RiquadroMessaggio(testo: state.messaggio),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: BottonePieno(
                            testo: 'Annulla',
                            sfondo: Colori.sfondo,
                            coloreTesto: Colori.testo,
                            paddingOrizzontale: 8,
                            onPressed:
                                isLoading
                                    ? null
                                    : () {
                                      Navigator.pop(context);
                                    },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: BottonePieno(
                            testo: 'Esci',
                            sfondo: Colori.rosso,
                            paddingOrizzontale: 8,
                            inCaricamento: isLoading,
                            onPressed: () {
                              context.read<AuthBloc>().add(LogoutRichiesto());
                            },
                          ),
                        ),
                      ],
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

// "Elimina account" sotto a "Esci": stessa idea, ma l'operazione e' definitiva
// e quindi il link e il bottone di conferma sono rossi
class BottoneEliminaAccount extends StatelessWidget {
  const BottoneEliminaAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LinkTesto(
        testo: 'Elimina account',
        peso: FontWeight.w600,
        colore: Colori.rosso,
        onPressed: () {
          showDialog<void>(
            context: context,
            barrierColor: Colori.testo.withValues(alpha: 0.55),
            builder: (_) => const _DialogEliminaAccount(),
          );
        },
      ),
    );
  }
}

class _DialogEliminaAccount extends StatelessWidget {
  const _DialogEliminaAccount();

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>(),
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                // La SnackBar parte prima di cambiare pagina: lo
                // ScaffoldMessenger e' quello dell'app, quindi resta visibile
                // anche sulla pagina di login.
                if (state is AccountEliminato) {
                  mostraSnackBar(context, 'Account eliminato');
                  tornaAllaVoce(context, const LoginPage());
                }
                // dietro al dialog la SnackBar resterebbe in ombra: prima lo
                // chiudiamo
                if (state is AuthErrore) {
                  mostraSnackBar(context, state.messaggio);
                  Navigator.pop(context);
                }
              },
              builder: (context, state) {
                final bool isLoading = state is AuthLoading;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Eliminare l\'account?', style: stileNumero(r, 22)),
                    const SizedBox(height: 8),
                    Text(
                      'Il tuo account e i tuoi dati personali verranno '
                      'eliminati. Non si può annullare.',
                      style: stileSecondario(r),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: BottonePieno(
                            testo: 'Annulla',
                            sfondo: Colori.sfondo,
                            coloreTesto: Colori.testo,
                            paddingOrizzontale: 8,
                            onPressed:
                                isLoading
                                    ? null
                                    : () {
                                      Navigator.pop(context);
                                    },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: BottonePieno(
                            testo: 'Elimina',
                            sfondo: Colori.rosso,
                            paddingOrizzontale: 8,
                            inCaricamento: isLoading,
                            onPressed: () {
                              context.read<AuthBloc>().add(
                                EliminaAccountRichiesto(),
                              );
                            },
                          ),
                        ),
                      ],
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
