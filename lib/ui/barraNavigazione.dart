import 'dart:ui';

import 'package:flutter/material.dart';

import 'bachecaInviti.dart';
import 'bachecaPubbliche.dart';
import 'classifica.dart';
import 'fontApp.dart';
import 'home.dart';
import 'miePartite.dart';
import 'prenota.dart';
import 'stileApp.dart';
import 'storico.dart';

enum VoceBarra { home, prenota, miePartite, partite, storico, classifica }

// Le voci nell'ordine in cui compaiono nella barra: serve per sapere dove
// mettere il cerchio della voce attiva.
const List<VoceBarra> _ordineVoci = [
  VoceBarra.home,
  VoceBarra.prenota,
  VoceBarra.miePartite,
  VoceBarra.partite,
  VoceBarra.storico,
  VoceBarra.classifica,
];

// Ogni pagina ha la sua barra, quindi quella nuova non sa da dove si arriva.
// Prima di cambiare pagina ci si segna la voce lasciata: la barra nuova fa
// partire il cerchio da li' e lo porta sulla sua voce.
VoceBarra? _vocePrecedente;

// Le voci della barra si sostituiscono tra loro senza animazione: sono pagine
// allo stesso livello, non una sopra l'altra.
void cambiaPagina(BuildContext context, Widget pagina) {
  Navigator.pushReplacement(context, _rottaSenzaAnimazione(pagina));
}

// Da una pagina di dettaglio si torna a una voce della barra togliendo
// tutto quello che c'e' sotto.
void tornaAllaVoce(BuildContext context, Widget pagina) {
  Navigator.pushAndRemoveUntil(context, _rottaSenzaAnimazione(pagina), (rotta) {
    return false;
  });
}

PageRouteBuilder<void> _rottaSenzaAnimazione(Widget pagina) {
  return PageRouteBuilder<void>(
    pageBuilder: (context, animazione, animazioneSecondaria) => pagina,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}

class BarraNavigazione extends StatefulWidget {
  final VoceBarra voceAttiva;

  const BarraNavigazione({super.key, required this.voceAttiva});

  @override
  State<BarraNavigazione> createState() => _BarraNavigazioneState();
}

class _BarraNavigazioneState extends State<BarraNavigazione> {
  // da dove parte il cerchio la prima volta che la barra si disegna
  late final int _indicePartenza;

  @override
  void initState() {
    super.initState();
    final VoceBarra? precedente = _vocePrecedente;
    _vocePrecedente = null;
    if (precedente == null) {
      _indicePartenza = _ordineVoci.indexOf(widget.voceAttiva);
    } else {
      _indicePartenza = _ordineVoci.indexOf(precedente);
    }
  }

  void _vaiA(BuildContext context, VoceBarra voce) {
    if (voce == widget.voceAttiva) {
      return;
    }
    _vocePrecedente = widget.voceAttiva;
    if (voce == VoceBarra.home) {
      cambiaPagina(context, const HomePage());
    }
    if (voce == VoceBarra.prenota) {
      cambiaPagina(context, const PrenotaPage());
    }
    if (voce == VoceBarra.miePartite) {
      cambiaPagina(context, const MiePartitePage());
    }
    if (voce == VoceBarra.partite) {
      cambiaPagina(context, const BachecaPubblichePage());
    }
    if (voce == VoceBarra.storico) {
      cambiaPagina(context, const StoricoPage());
    }
    if (voce == VoceBarra.classifica) {
      cambiaPagina(context, const ClassificaPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    // sui telefoni piccoli si recupera un po' di spazio per le sei voci
    final double margine = r.width < 360 ? 8 : 12;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(margine, 0, margine, 8),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colori.bordo),
            boxShadow: [
              BoxShadow(
                color: Colori.testo.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double larghezzaVoce =
                  constraints.maxWidth / _ordineVoci.length;
              double diametro = larghezzaVoce - 2;
              if (diametro > 56) {
                diametro = 56;
              }

              final List<Widget> voci = [];
              for (final voce in _ordineVoci) {
                voci.add(_voce(context, r, voce));
              }

              return Stack(
                children: [
                  Row(children: voci),
                  // il cerchio scivola dalla voce di prima a quella attuale
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: _indicePartenza.toDouble(),
                      end: _ordineVoci.indexOf(widget.voceAttiva).toDouble(),
                    ),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    builder: (context, indice, child) {
                      return Positioned(
                        left:
                            indice * larghezzaVoce +
                            (larghezzaVoce - diametro) / 2,
                        top: (64 - 2 - diametro) / 2,
                        width: diametro,
                        height: diametro,
                        child: child!,
                      );
                    },
                    child: const _CerchioVetro(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _voce(BuildContext context, Responsive r, VoceBarra voce) {
    final bool attiva = voce == widget.voceAttiva;
    final Color colore = attiva ? Colori.testo : Colori.testoSecondario;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _vaiA(context, voce);
        },
        child: Semantics(
          selected: attiva,
          label: voce == VoceBarra.miePartite ? 'Le mie partite' : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CustomPaint(
                  painter: _IconaVocePainter(
                    voce: voce,
                    colore: colore,
                    spessore: attiva ? 2 : 1.8,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _etichetta(voce),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  // la voce Bacheca usa il font dei titoli, come la sua pagina
                  fontFamily:
                      voce == VoceBarra.partite
                          ? FontApp.titoli
                          : FontApp.testo,
                  fontVariations:
                      voce == VoceBarra.partite
                          ? [FontVariation.weight(attiva ? 700 : 600)]
                          : null,
                  // con sei voci il testo e' un po' piu' piccolo di prima
                  fontSize: r.isTablet ? 14 : r.font(11.5),
                  fontWeight: attiva ? FontWeight.w700 : FontWeight.w600,
                  color: colore,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _etichetta(VoceBarra voce) {
    if (voce == VoceBarra.home) {
      return 'Home';
    }
    if (voce == VoceBarra.prenota) {
      return 'Prenota';
    }
    if (voce == VoceBarra.miePartite) {
      return 'Partite';
    }
    if (voce == VoceBarra.partite) {
      return 'Bacheca';
    }
    if (voce == VoceBarra.storico) {
      return 'Storico';
    }
    return 'Classifica';
  }
}

// Il cerchio "di vetro" sopra la voce attiva: sfoca appena quello che ha sotto
// e lo schiarisce, con un bordo chiaro e un riflesso in alto a sinistra.
// Non riceve tocchi, cosi' la voce sotto resta toccabile.
class _CerchioVetro extends StatelessWidget {
  const _CerchioVetro();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colori.primario.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 1.2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colori.primario.withValues(alpha: 0.10),
                    Colori.primario.withValues(alpha: 0.22),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Le icone sono le stesse dei prototipi: le coordinate sono su una griglia
// 24x24 e vengono scalate alla dimensione reale.
class _IconaVocePainter extends CustomPainter {
  final VoceBarra voce;
  final Color colore;
  final double spessore;

  _IconaVocePainter({
    required this.voce,
    required this.colore,
    required this.spessore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);

    final Paint pennello =
        Paint()
          ..color = colore
          ..strokeWidth = spessore
          ..style = PaintingStyle.stroke;

    if (voce == VoceBarra.home) {
      final Path casa =
          Path()
            ..moveTo(4, 11)
            ..lineTo(12, 4)
            ..lineTo(20, 11)
            ..lineTo(20, 20)
            ..lineTo(15, 20)
            ..lineTo(15, 14)
            ..lineTo(9, 14)
            ..lineTo(9, 20)
            ..lineTo(4, 20)
            ..close();
      canvas.drawPath(casa, pennello);
    }
    if (voce == VoceBarra.prenota) {
      canvas.drawRRect(
        RRect.fromLTRBR(4, 5, 20, 20, const Radius.circular(2)),
        pennello,
      );
      canvas.drawLine(const Offset(4, 10), const Offset(20, 10), pennello);
      canvas.drawLine(const Offset(9, 3), const Offset(9, 7), pennello);
      canvas.drawLine(const Offset(15, 3), const Offset(15, 7), pennello);
    }
    // la bacheca: quattro riquadri come l'icona dashboard di Material
    if (voce == VoceBarra.partite) {
      const Radius angolo = Radius.circular(1.5);
      canvas.drawRRect(RRect.fromLTRBR(4, 4, 11, 13, angolo), pennello);
      canvas.drawRRect(RRect.fromLTRBR(13, 4, 20, 9, angolo), pennello);
      canvas.drawRRect(RRect.fromLTRBR(13, 11, 20, 20, angolo), pennello);
      canvas.drawRRect(RRect.fromLTRBR(4, 15, 11, 20, angolo), pennello);
    }
    // le mie partite: una racchetta da padel
    if (voce == VoceBarra.miePartite) {
      canvas.drawCircle(const Offset(10, 10), 6, pennello);
      canvas.drawLine(const Offset(14.5, 14.5), const Offset(20, 20), pennello);
      canvas.drawCircle(const Offset(10, 10), 0.8, pennello);
    }
    if (voce == VoceBarra.storico) {
      canvas.drawCircle(const Offset(12, 12), 8, pennello);
      final Path lancette =
          Path()
            ..moveTo(12, 7)
            ..lineTo(12, 12)
            ..lineTo(15, 14);
      canvas.drawPath(lancette, pennello);
    }
    if (voce == VoceBarra.classifica) {
      canvas.drawLine(const Offset(6, 20), const Offset(6, 13), pennello);
      canvas.drawLine(const Offset(12, 20), const Offset(12, 5), pennello);
      canvas.drawLine(const Offset(18, 20), const Offset(18, 10), pennello);
    }
  }

  @override
  bool shouldRepaint(_IconaVocePainter oldDelegate) {
    return oldDelegate.voce != voce ||
        oldDelegate.colore != colore ||
        oldDelegate.spessore != spessore;
  }
}

// Le due schede in cima alla Bacheca. Il conteggio c'e' solo sulla scheda
// attiva: l'altra pagina non e' caricata e un numero vecchio confonderebbe.
class SchedePartite extends StatelessWidget {
  final bool inviti;
  final String? conteggio;
  final bool inCaricamento;

  const SchedePartite({
    super.key,
    required this.inviti,
    required this.conteggio,
    this.inCaricamento = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _scheda(
              context,
              nome: 'Pubbliche',
              attiva: !inviti,
              onTap: () {
                cambiaPagina(context, const BachecaPubblichePage());
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _scheda(
              context,
              nome: 'Inviti',
              attiva: inviti,
              onTap: () {
                cambiaPagina(context, const BachecaInvitiPage());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheda(
    BuildContext context, {
    required String nome,
    required bool attiva,
    required VoidCallback onTap,
  }) {
    final r = Responsive(context);

    final List<Widget> righe = [];
    if (attiva) {
      righe.add(Text(nome, style: stileSecondario(r, base: 13)));
      if (inCaricamento) {
        righe.add(const SizedBox(height: 2));
        righe.add(const BarraGrigia(larghezza: 70, altezza: 20));
      } else if (conteggio != null) {
        righe.add(
          Text(
            conteggio!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: stileTesto(r, base: 16, peso: FontWeight.w600),
          ),
        );
      }
    } else {
      righe.add(
        Text(nome, style: stileTesto(r, base: 16, peso: FontWeight.w600)),
      );
    }

    return Material(
      color: attiva ? Colori.azzurroChiaro : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: attiva ? Colori.primario : Colori.bordo,
          width: attiva ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        // la scheda gia' attiva non fa nulla: ricaricarla sarebbe uno sfarfallio
        onTap: attiva ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: righe,
          ),
        ),
      ),
    );
  }
}
