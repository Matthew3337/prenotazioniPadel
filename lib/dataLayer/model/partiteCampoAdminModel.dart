import 'package:thepadel/dataLayer/model/partitaAdminModel.dart';
import 'package:thepadel/domainLayer/enetity/partiteCampoAdmin.dart';

class PartiteCampoAdminModel extends PartiteCampoAdmin{

  PartiteCampoAdminModel({required super.idCampo, required super.nomeCampo, required super.partite});

  factory PartiteCampoAdminModel.fromJson(Map<String, dynamic> json)
  {
    List<dynamic> partiteJson = json['partite'] as List<dynamic>;
    List<PartitaAdminModel> partite = partiteJson.map((e) => PartitaAdminModel.fromJson(e as Map<String, dynamic>)).toList();

    return PartiteCampoAdminModel(
      idCampo: json['idCampo'] as int,
      nomeCampo: json['nomeCampo'] as String,
      partite: partite
    );
  }
}
