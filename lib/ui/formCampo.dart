import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/gestioneCampi/gestioneCampiBloc.dart';
import 'package:thepadel/bloc/gestioneCampi/gestioneCampiEvent.dart';
import 'package:thepadel/bloc/gestioneCampi/gestioneCampiState.dart';
import 'package:thepadel/domainLayer/enetity/campo.dart';

import 'stileApp.dart';

class FormCampoPage extends StatelessWidget {
  // null quando si sta creando un campo nuovo
  final Campo? campo;
  // il bloc dell'elenco: deve sapere dell'operazione per mostrare la lista
  // aggiornata quando si torna indietro
  final GestioneCampiBloc bloc;

  const FormCampoPage({super.key, this.campo, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GestioneCampiBloc>.value(
      value: bloc,
      child: _FormCampoView(campo: campo),
    );
  }
}

class _FormCampoView extends StatefulWidget {
  final Campo? campo;

  const _FormCampoView({required this.campo});

  @override
  State<_FormCampoView> createState() => _FormCampoViewState();
}

class _FormCampoViewState extends State<_FormCampoView> {
  final TextEditingController _nomeController = TextEditingController();
  bool _alCoperto = false;
  TimeOfDay _oraApertura = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _oraChiusura = const TimeOfDay(hour: 23, minute: 0);

  // L'errore lo teniamo qui e non lo leggiamo dallo stato del bloc: il bloc
  // vive piu' a lungo del form, e riaprendolo si rivedrebbe l'errore precedente.
  String? _errore;

  @override
  void initState() {
    super.initState();
    final Campo? campo = widget.campo;
    if (campo != null) {
      _nomeController.text = campo.nome;
      _alCoperto = campo.alCoperto;
      _oraApertura = campo.oraApertura;
      _oraChiusura = campo.oraChiusura;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _salva() {
    setState(() {
      _errore = null;
    });
    context.read<GestioneCampiBloc>().add(
      SalvaCampoRichiesto(
        id: widget.campo?.id,
        nome: _nomeController.text.trim(),
        alCoperto: _alCoperto,
        oraApertura: _oraApertura,
        oraChiusura: _oraChiusura,
      ),
    );
  }

  Future<void> _confermaElimina(Campo campo) async {
    final bool? confermato = await showDialog<bool>(
      context: context,
      barrierColor: Colori.testo.withValues(alpha: 0.55),
      builder: (dialogContext) {
        return FinestraConferma(
          titolo: 'Eliminare il campo?',
          testo: '${campo.nome} verrà eliminato definitivamente.',
          testoConferma: 'Elimina',
        );
      },
    );

    if (confermato == true && mounted) {
      setState(() {
        _errore = null;
      });
      context.read<GestioneCampiBloc>().add(
        EliminaCampoRichiesto(id: campo.id),
      );
    }
  }

  // la tastiera si chiude prima, altrimenti coprirebbe parte del selettore
  Future<TimeOfDay?> _scegliOra(TimeOfDay oraAttuale) {
    FocusScope.of(context).unfocus();
    return showTimePicker(context: context, initialTime: oraAttuale);
  }

  Future<void> _scegliApertura() async {
    final TimeOfDay? scelta = await _scegliOra(_oraApertura);
    if (scelta != null && mounted) {
      setState(() {
        _oraApertura = scelta;
      });
    }
  }

  Future<void> _scegliChiusura() async {
    final TimeOfDay? scelta = await _scegliOra(_oraChiusura);
    if (scelta != null && mounted) {
      setState(() {
        _oraChiusura = scelta;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final Campo? campo = widget.campo;

    return Scaffold(
      backgroundColor: Colori.sfondo,
      body: SafeArea(
        child: ContenutoCentrato(
          child: BlocConsumer<GestioneCampiBloc, GestioneCampiState>(
            listener: (context, state) {
              if (state is CampoSalvato) {
                mostraSnackBar(context, 'Campo salvato');
                Navigator.pop(context);
              }
              if (state is CampoEliminato) {
                mostraSnackBar(context, 'Campo eliminato');
                Navigator.pop(context);
              }
              if (state is CampoOperazioneErrore) {
                setState(() {
                  _errore = state.messaggio;
                });
              }
            },
            builder: (context, state) {
              final bool isLoading = state is CampoInCorso;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TestataIndietro(
                    titolo: campo == null ? 'Nuovo campo' : 'Modifica campo',
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildNome(r, isLoading),
                          const SizedBox(height: 16),
                          _buildDati(r, isLoading),
                          const SizedBox(height: 8),
                          Text(
                            'La chiusura può essere anche dopo mezzanotte.',
                            style: stileSecondario(r, base: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildAzioni(campo, isLoading),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ===== NOME =====

  Widget _buildNome(Responsive r, bool isLoading) {
    const OutlineInputBorder bordo = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Colori.grigio),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nome', style: stileTesto(r, peso: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: _nomeController,
          enabled: !isLoading,
          textCapitalization: TextCapitalization.sentences,
          style: stileTesto(r),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: bordo,
            enabledBorder: bordo,
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Colori.azzurro, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // ===== COPERTURA E ORARI =====

  Widget _buildDati(Responsive r, bool isLoading) {
    return CardBianca(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Al coperto',
                    style: stileTesto(r, peso: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _alCoperto,
                  activeTrackColor: Colori.primario,
                  onChanged:
                      isLoading
                          ? null
                          : (valore) {
                            setState(() {
                              _alCoperto = valore;
                            });
                          },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colori.bordo),
          _rigaOra(
            r,
            titolo: 'Ora di apertura',
            ora: _oraApertura,
            onTap: isLoading ? null : _scegliApertura,
          ),
          const Divider(height: 1, color: Colori.bordo),
          _rigaOra(
            r,
            titolo: 'Ora di chiusura',
            ora: _oraChiusura,
            onTap: isLoading ? null : _scegliChiusura,
          ),
        ],
      ),
    );
  }

  Widget _rigaOra(
    Responsive r, {
    required String titolo,
    required TimeOfDay ora,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            Expanded(
              child: Text(titolo, style: stileTesto(r, peso: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Text(
              formattaOra(ora),
              style: stileTesto(r, peso: FontWeight.w700, colore: Colori.bluCampo),
            ),
          ],
        ),
      ),
    );
  }

  // ===== AZIONI =====

  Widget _buildAzioni(Campo? campo, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errore != null) ...[
            RiquadroMessaggio(testo: _errore!),
            const SizedBox(height: 8),
          ],
          BottonePieno(
            testo: 'Salva',
            altezza: 52,
            baseFont: 16,
            inCaricamento: isLoading,
            onPressed: _salva,
          ),
          if (campo != null) ...[
            const SizedBox(height: 4),
            LinkTesto(
              testo: 'Elimina campo',
              peso: FontWeight.w600,
              colore: Colori.rosso,
              onPressed:
                  isLoading
                      ? null
                      : () {
                        _confermaElimina(campo);
                      },
            ),
          ],
        ],
      ),
    );
  }
}
