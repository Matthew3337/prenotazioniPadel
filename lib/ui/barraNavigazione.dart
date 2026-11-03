import 'package:flutter/material.dart';

import 'bachecaInviti.dart';
import 'bachecaPubbliche.dart';
import 'classifica.dart';
import 'home.dart';
import 'prenota.dart';
import 'stileApp.dart';
import 'storico.dart';

enum VoceBarra { home, prenota, partite, storico, classifica }

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

class BarraNavigazione extends StatelessWidget {
  final VoceBarra voceAttiva;

  const BarraNavigazione({super.key, required this.voceAttiva});

  void _vaiA(BuildContext context, VoceBarra voce) {
    if (voce == voceAttiva) {
      return;
    }
    if (voce == VoceBarra.home) {
      cambiaPagina(context, const HomePage());
    }
    if (voce == VoceBarra.prenota) {
      cambiaPagina(context, const PrenotaPage());
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colori.bordo)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _voce(context, VoceBarra.home, 'Home'),
              _voce(context, VoceBarra.prenota, 'Prenota'),
              _voce(context, VoceBarra.partite, 'Partite'),
              _voce(context, VoceBarra.storico, 'Storico'),
              _voce(context, VoceBarra.classifica, 'Classifica'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _voce(BuildContext context, VoceBarra voce, String testo) {
    final r = Responsive(context);
    final bool attiva = voce == voceAttiva;
    final Color colore = attiva ? Colori.bluCampo : Colori.testoSecondario;

    return Expanded(
      child: InkWell(
        onTap: () {
          _vaiA(context, voce);
        },
        child: Semantics(
          selected: attiva,
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
                testo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  // sul tablet il prototipo usa un testo piu' grande
                  fontSize: r.isTablet ? 14 : r.font(12),
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
    if (voce == VoceBarra.partite) {
      canvas.drawRRect(
        RRect.fromLTRBR(3, 6, 21, 18, const Radius.circular(1)),
        pennello,
      );
      canvas.drawLine(const Offset(12, 4), const Offset(12, 20), pennello);
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

// Le due schede in cima a Partite. Il conteggio c'e' solo sulla scheda
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
      righe.add(Text(nome, style: stileTesto(r, base: 16, peso: FontWeight.w600)));
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
