// Une prévision de l'API météo (un créneau de 3 heures).
class PrevisionMeteo {
  final DateTime instant; // en UTC
  final double temperature; // °C
  final double ressenti; // °C
  final int humidite; // %
  final double vent; // m/s
  final double rafale; // m/s
  final int nuages; // %
  final double pluieMm; // sur 3 heures
  final double probabilitePluie; // de 0 à 1
  final int visibilite; // mètres
  final int idCondition; // code de la condition météo
  final String icone;

  PrevisionMeteo({
    required this.instant,
    required this.temperature,
    required this.ressenti,
    required this.humidite,
    required this.vent,
    required this.rafale,
    required this.nuages,
    required this.pluieMm,
    required this.probabilitePluie,
    required this.visibilite,
    required this.idCondition,
    required this.icone,
  });

  // L'API renvoie les températures en Kelvin.
  static double _celsius(dynamic kelvin) {
    return (kelvin as num).toDouble() - 273.15;
  }

  factory PrevisionMeteo.fromJson(Map<String, dynamic> json) {
    final principal = json['main'] as Map<String, dynamic>;
    final condition = (json['weather'] as List).first as Map<String, dynamic>;
    final vent = (json['wind'] as Map<String, dynamic>?) ?? {};
    final pluie = (json['rain'] as Map<String, dynamic>?) ?? {};
    final nuages = (json['clouds'] as Map<String, dynamic>?) ?? {};

    double vitesse = (vent['speed'] as num?)?.toDouble() ?? 0;

    return PrevisionMeteo(
      instant: DateTime.fromMillisecondsSinceEpoch(
        (json['dt'] as num).toInt() * 1000,
        isUtc: true,
      ),
      temperature: _celsius(principal['temp']),
      ressenti: _celsius(principal['feels_like']),
      humidite: (principal['humidity'] as num?)?.toInt() ?? 0,
      vent: vitesse,
      rafale: (vent['gust'] as num?)?.toDouble() ?? vitesse,
      nuages: (nuages['all'] as num?)?.toInt() ?? 0,
      pluieMm: (pluie['3h'] as num?)?.toDouble() ??
          (pluie['1h'] as num?)?.toDouble() ??
          0,
      probabilitePluie: (json['pop'] as num?)?.toDouble() ?? 0,
      visibilite: (json['visibility'] as num?)?.toInt() ?? 10000,
      idCondition: (condition['id'] as num).toInt(),
      icone: (condition['icon'] ?? '').toString(),
    );
  }
}