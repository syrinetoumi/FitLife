enum MethodePaiement {
  carte,
  virement,
  especes,
}

enum StatutPaiement {
  enAttente,
  paye,
  echoue,
  rembourse,
}

String methodePaiementEnTexte(MethodePaiement methode) {
  if (methode == MethodePaiement.virement) {
    return 'VIREMENT';
  }

  if (methode == MethodePaiement.especes) {
    return 'ESPECES';
  }

  return 'CARTE';
}

String statutPaiementEnTexte(StatutPaiement statut) {
  if (statut == StatutPaiement.paye) {
    return 'PAYE';
  }

  if (statut == StatutPaiement.echoue) {
    return 'ECHOUE';
  }

  if (statut == StatutPaiement.rembourse) {
    return 'REMBOURSE';
  }

  return 'EN_ATTENTE';
}

class PaiementEvenement {
  String idPaiement;
  String idInscription;
  double montant;
  DateTime datePaiement;
  MethodePaiement methode;
  StatutPaiement statut;
  String reference;

  PaiementEvenement({
    required this.idPaiement,
    required this.idInscription,
    required this.montant,
    required this.datePaiement,
    required this.methode,
    required this.statut,
    required this.reference,
  });

  String methodeToString() {
    return methodePaiementEnTexte(methode);
  }

  String statutToString() {
    return statutPaiementEnTexte(statut);
  }

  Map<String, dynamic> toMap() {
    return {
      'id_inscription': idInscription,
      'montant': montant,
      'date_paiement': datePaiement.toUtc().toIso8601String(),
      'methode': methodeToString(),
      'statut': statutToString(),
      'reference': reference,
    };
  }

  factory PaiementEvenement.fromMap(Map<String, dynamic> data) {
    MethodePaiement methode = MethodePaiement.carte;

    if (data['methode'] == 'VIREMENT') {
      methode = MethodePaiement.virement;
    }

    if (data['methode'] == 'ESPECES') {
      methode = MethodePaiement.especes;
    }

    StatutPaiement statut = StatutPaiement.enAttente;

    if (data['statut'] == 'PAYE') {
      statut = StatutPaiement.paye;
    }

    if (data['statut'] == 'ECHOUE') {
      statut = StatutPaiement.echoue;
    }

    if (data['statut'] == 'REMBOURSE') {
      statut = StatutPaiement.rembourse;
    }

    return PaiementEvenement(
      idPaiement: data['id'].toString(),
      idInscription: data['id_inscription'].toString(),
      montant: double.parse(data['montant'].toString()),
      datePaiement: DateTime.parse(data['date_paiement']).toLocal(),
      methode: methode,
      statut: statut,
      reference: data['reference'] ?? '',
    );
  }
}
