import 'suivi_objectif.dart';

class MesureProgression {
  final int? id;
  final int idSuivi;
  final DateTime dateMesure;
  final double valeur;
  final String? note;

  MesureProgression({
    this.id,
    required this.idSuivi,
    required this.dateMesure,
    required this.valeur,
    this.note,
  });

  factory MesureProgression.fromJson(Map<String, dynamic> json) {
    return MesureProgression(
      id: json['id_mesure'] as int?,
      idSuivi: json['id_suivi'] as int,
      dateMesure: DateTime.parse(json['date_mesure'] as String),
      valeur: (json['valeur'] as num).toDouble(),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_suivi': idSuivi,
    'date_mesure': dateSql(dateMesure),
    'valeur': valeur,
    'note': note,
  };
}