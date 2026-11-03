import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/domainLayer/enetity/distaccoClassifica.dart';

void main()
{
  test("conserva punti e posizione sopra", ()
  {
    final distacco = DistaccoClassifica(punti: 7, posizioneSopra: 2);

    expect(distacco.punti, 7);
    expect(distacco.posizioneSopra, 2);
  });

  test("chi e primo ha entrambi i campi null", ()
  {
    final distacco = DistaccoClassifica(punti: null, posizioneSopra: null);

    expect(distacco.punti, isNull);
    expect(distacco.posizioneSopra, isNull);
  });
}
