import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/domainLayer/enetity/invitoBacheca.dart';

import '../../fake/fakePartitaRepo.dart';

void main()
{
  test("conserva la partita e cosa l'utente puo farci", ()
  {
    final partita = partitaInvitoDiTest(id: 12);

    final voce = InvitoBacheca(partita: partita, puoConfermare: true, giaConfermato: false);

    expect(identical(voce.partita, partita), true);
    expect(voce.puoConfermare, true);
    expect(voce.giaConfermato, false);
  });
}
