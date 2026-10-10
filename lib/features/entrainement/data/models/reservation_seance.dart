import 'enums.dart';

class ReservationSeance {
  final int? id;
  final int idSeance;
  final String idAthlete;
  final DateTime? dateReservation;
  final StatutReservation statut;

  ReservationSeance({
    this.id,
    required this.idSeance,
    required this.idAthlete,
    this.dateReservation,
    this.statut = StatutReservation.CONFIRMEE,
  });

  factory ReservationSeance.fromJson(Map<String, dynamic> j) =>
      ReservationSeance(
        id: j['id_reservation'],
        idSeance: j['id_seance'],
        idAthlete: j['id_athlete'],
        dateReservation: j['date_reservation'] != null
            ? DateTime.parse(j['date_reservation'])
            : null,
        statut: StatutReservation.values.byName(j['statut']),
      );

  Map<String, dynamic> toJson() => {
    'id_seance': idSeance,
    'id_athlete': idAthlete,
    'statut': statut.name,
  };
}