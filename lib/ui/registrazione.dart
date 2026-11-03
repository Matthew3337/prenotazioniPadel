import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/autenticazione/authBloc.dart';
import 'package:thepadel/bloc/autenticazione/authState.dart';
import 'package:thepadel/bloc/autenticazione/authevent.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';

import 'stileApp.dart';

class RegistrazionePage extends StatefulWidget {
  const RegistrazionePage({super.key});

  @override
  State<RegistrazionePage> createState() => RegistrazionePageState();
}

class RegistrazionePageState extends State<RegistrazionePage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const Scaffold(
        backgroundColor: Colors.white,
        body: _RegistrazioneForm(),
      ),
    );
  }
}

class _RegistrazioneForm extends StatefulWidget {
  const _RegistrazioneForm();

  @override
  State<_RegistrazioneForm> createState() => _RegistrazioneFormState();
}

class _RegistrazioneFormState extends State<_RegistrazioneForm> {
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _dataNascita;

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selezionaData(BuildContext context) async {
    final now = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: _dataNascita ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colori.bluCampo,
              onPrimary: Colors.white,
              onSurface: Colori.testo,
            ),
          ),
          child: child!,
        );
      },
    );
    if (data != null) {
      setState(() {
        _dataNascita = data;
      });
    }
  }

  String _formattaData(DateTime data) {
    final gg = data.day.toString().padLeft(2, '0');
    final mm = data.month.toString().padLeft(2, '0');
    return '$gg/$mm/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 468),
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is RegistrazioneSuccess) {
                mostraSnackBar(
                  context,
                  'Registrazione avvenuta con successo, effettua il login',
                );
                Navigator.of(context).pop();
              }
            },
            builder: (context, state) {
              final bool isLoading = state is AuthLoading;

              // un errore alla volta: quello col campo va sotto il suo campo,
              // quello generale in un riquadro sopra il bottone
              CampoErroreAuth campoErrato = CampoErroreAuth.nessuno;
              String? erroreGenerale;
              String messaggioCampo = '';
              if (state is AuthErrore) {
                campoErrato = state.campo;
                if (state.campo == CampoErroreAuth.nessuno) {
                  erroreGenerale = state.messaggio;
                } else {
                  messaggioCampo = state.messaggio;
                }
              }

              String? errore(CampoErroreAuth campo) {
                if (campo == campoErrato) {
                  return messaggioCampo;
                }
                return null;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Torna al login',
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed:
                            isLoading
                                ? null
                                : () {
                                  Navigator.of(context).pop();
                                },
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: Colori.testo,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Crea il tuo account', style: stileTitolo(r)),
                          const SizedBox(height: 4),
                          Text(
                            'Accederai con il numero di telefono.',
                            style: stileSecondario(r),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _campoTesto(
                                  r,
                                  etichetta: 'Nome',
                                  controller: _nomeController,
                                  isLoading: isLoading,
                                  errore: errore(CampoErroreAuth.nome),
                                  suggerimento: AutofillHints.givenName,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _campoTesto(
                                  r,
                                  etichetta: 'Cognome',
                                  controller: _cognomeController,
                                  isLoading: isLoading,
                                  errore: errore(CampoErroreAuth.cognome),
                                  suggerimento: AutofillHints.familyName,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _campoData(
                            context,
                            r,
                            isLoading,
                            errore(CampoErroreAuth.dataNascita),
                          ),
                          const SizedBox(height: 12),
                          _campoTesto(
                            r,
                            etichetta: 'Telefono',
                            controller: _telefonoController,
                            isLoading: isLoading,
                            errore: errore(CampoErroreAuth.telefono),
                            tastiera: TextInputType.phone,
                            suggerimento: AutofillHints.telephoneNumber,
                          ),
                          const SizedBox(height: 12),
                          _campoTesto(
                            r,
                            etichetta: 'Password',
                            controller: _passwordController,
                            isLoading: isLoading,
                            errore: errore(CampoErroreAuth.password),
                            nascosto: true,
                            suggerimento: AutofillHints.newPassword,
                          ),
                          const SizedBox(height: 16),
                          if (erroreGenerale != null) ...[
                            _buildErroreGenerale(context, erroreGenerale),
                            const SizedBox(height: 12),
                          ],
                          BottonePieno(
                            testo: isLoading ? 'Attendi…' : 'Registrati',
                            altezza: 52,
                            baseFont: 16,
                            onPressed:
                                isLoading
                                    ? null
                                    : () {
                                      _registrati(context);
                                    },
                          ),
                          const SizedBox(height: 4),
                          _buildVaiALogin(context, r, isLoading),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _registrati(BuildContext context) {
    context.read<AuthBloc>().add(
      RegistrazioneRichiesta(
        nome: _nomeController.text,
        cognome: _cognomeController.text,
        telefono: _telefonoController.text,
        // lo use case riconosce DateTime(0) come data non inserita
        dataNascita: _dataNascita ?? DateTime(0),
        pw: _passwordController.text,
      ),
    );
  }

  // ===== ERRORI =====

  Widget _buildErroreGenerale(BuildContext context, String messaggio) {
    // lo stato porta solo il testo: dal testo si capisce se il numero esiste
    // gia', e in quel caso la cosa utile da proporre e' il login
    if (messaggio == TelefonoDuplicatoException().messaggio) {
      return RiquadroMessaggio(
        testo: messaggio,
        sfondo: Colori.arancioChiaro,
        colore: Colori.arancio,
        azione: LinkTesto(
          testo: 'Accedi',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      );
    }
    return RiquadroMessaggio(testo: messaggio);
  }

  // ===== CAMPI =====

  OutlineInputBorder _bordo(Color colore, double spessore) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colore, width: spessore),
    );
  }

  InputDecoration _decorazione(bool inErrore, bool isLoading) {
    return InputDecoration(
      filled: true,
      fillColor: isLoading ? Colori.sfondo : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      enabledBorder:
          inErrore ? _bordo(Colori.rosso, 2) : _bordo(Colori.grigio, 1),
      disabledBorder: _bordo(Colori.bordo, 1),
      focusedBorder:
          inErrore ? _bordo(Colori.rosso, 2) : _bordo(Colori.azzurro, 2),
    );
  }

  Widget _campoTesto(
    Responsive r, {
    required String etichetta,
    required TextEditingController controller,
    required bool isLoading,
    required String? errore,
    required String suggerimento,
    TextInputType tastiera = TextInputType.text,
    bool nascosto = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etichetta, style: stileTesto(r, peso: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: !isLoading,
          keyboardType: tastiera,
          obscureText: nascosto,
          autofillHints: [suggerimento],
          style: stileTesto(r, base: 16),
          decoration: _decorazione(errore != null, isLoading),
        ),
        if (errore != null) _testoErrore(r, errore),
      ],
    );
  }

  Widget _testoErrore(Responsive r, String messaggio) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        messaggio,
        style: stileTesto(
          r,
          base: 14,
          peso: FontWeight.w600,
          colore: Colori.rosso,
        ),
      ),
    );
  }

  // la data si sceglie dal calendario, cosi' non si puo' inserirne una
  // inesistente; l'aspetto resta quello degli altri campi
  Widget _campoData(
    BuildContext context,
    Responsive r,
    bool isLoading,
    String? errore,
  ) {
    final DateTime? data = _dataNascita;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data di nascita', style: stileTesto(r, peso: FontWeight.w600)),
        const SizedBox(height: 4),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap:
              isLoading
                  ? null
                  : () {
                    _selezionaData(context);
                  },
          child: InputDecorator(
            isEmpty: false,
            decoration: _decorazione(errore != null, isLoading),
            child: Text(
              data == null ? 'gg/mm/aaaa' : _formattaData(data),
              style:
                  data == null
                      ? stileSecondario(r, base: 16)
                      : stileTesto(r, base: 16),
            ),
          ),
        ),
        if (errore != null) _testoErrore(r, errore),
      ],
    );
  }

  Widget _buildVaiALogin(BuildContext context, Responsive r, bool isLoading) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Hai già un account? ', style: stileSecondario(r)),
        LinkTesto(
          testo: 'Accedi',
          onPressed:
              isLoading
                  ? null
                  : () {
                    Navigator.of(context).pop();
                  },
        ),
      ],
    );
  }
}
