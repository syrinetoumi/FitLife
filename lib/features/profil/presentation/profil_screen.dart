import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coach_app/core/utils/outils.dart';
import '../data/models/profil_utilisateur.dart';
import '../data/repositories/profil_repository.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  static const Color primaryBlue = Color(0xFF3843B8);
  static const Color dangerRed = Color(0xFFD32F2F);
  static const Color backgroundLight = Color(0xFFF7F8FC);
  static const Color mintAccent = Color(0xFF2E7D32);

  final ProfilRepository _repository = ProfilRepository();
  ProfilUtilisateur? _profil;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  Future<void> _chargerProfil() async {
    setState(() => _chargement = true);
    final p = await _repository.getProfilActuel();
    if (mounted) {
      setState(() {
        _profil = p;
        _chargement = false;
      });
    }
  }

  bool get _estConnecte {
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ouvrirDialogueModification() async {
    if (_profil == null) return;

    final nomController = TextEditingController(text: _profil!.nom ?? '');
    final prenomController = TextEditingController(text: _profil!.prenom ?? '');
    final telephoneController = TextEditingController(text: _profil!.telephone ?? '');
    final photoController = TextEditingController(text: _profil!.photo ?? '');

    String? genreSelectionne = _profil!.genre;
    DateTime? dateSelectionnee = _profil!.dateNaissance;
    final formKey = GlobalKey<FormState>();

    final resultat = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final dateTexte = dateSelectionnee != null
              ? '${dateSelectionnee!.day.toString().padLeft(2, '0')}/${dateSelectionnee!.month.toString().padLeft(2, '0')}/${dateSelectionnee!.year}'
              : 'Choisir une date';

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Modifier mes informations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Prénom
                    TextFormField(
                      controller: prenomController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        prefixIcon: Icon(Icons.badge_outlined, color: primaryBlue),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 12),

                    // Nom
                    TextFormField(
                      controller: nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        prefixIcon: Icon(Icons.person_outline, color: primaryBlue),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 12),

                    // Téléphone
                    TextFormField(
                      controller: telephoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone_outlined, color: primaryBlue),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Genre
                    DropdownButtonFormField<String>(
                      initialValue: genreSelectionne,
                      decoration: const InputDecoration(
                        labelText: 'Genre',
                        prefixIcon: Icon(Icons.wc, color: primaryBlue),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'HOMME', child: Text('Homme')),
                        DropdownMenuItem(value: 'FEMME', child: Text('Femme')),
                      ],
                      onChanged: (val) => setModalState(() => genreSelectionne = val),
                    ),
                    const SizedBox(height: 12),

                    // Date de naissance
                    InkWell(
                      onTap: () async {
                        final choix = await showDatePicker(
                          context: context,
                          initialDate: dateSelectionnee ?? DateTime(2000, 1, 1),
                          firstDate: DateTime(1940),
                          lastDate: DateTime.now(),
                        );
                        if (choix != null) {
                          setModalState(() => dateSelectionnee = choix);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date de naissance',
                          prefixIcon: Icon(Icons.cake_outlined, color: primaryBlue),
                        ),
                        child: Text(
                          dateTexte,
                          style: TextStyle(
                            color: dateSelectionnee != null ? Colors.black87 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Photo URL
                    TextFormField(
                      controller: photoController,
                      decoration: const InputDecoration(
                        labelText: 'URL de la photo (optionnel)',
                        prefixIcon: Icon(Icons.image_outlined, color: primaryBlue),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bouton Enregistrer
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            Navigator.pop(ctx, true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'ENREGISTRER LES MODIFICATIONS',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (resultat == true) {
      final nouveauProfil = _profil!.copyWith(
        nom: nomController.text.trim(),
        prenom: prenomController.text.trim(),
        telephone: telephoneController.text.trim().isEmpty ? null : telephoneController.text.trim(),
        genre: genreSelectionne,
        dateNaissance: dateSelectionnee,
        photo: photoController.text.trim().isEmpty ? null : photoController.text.trim(),
      );

      setState(() => _chargement = true);
      try {
        final maj = await _repository.mettreAJourProfil(nouveauProfil);
        setState(() {
          _profil = maj;
          _chargement = false;
        });
        if (mounted) {
          afficherMessage(context, 'Profil mis à jour avec succès !');
        }
      } catch (e) {
        setState(() => _chargement = false);
        if (mounted) {
          afficherMessage(context, 'Erreur lors de la sauvegarde : $e');
        }
      }
    }
  }

  Widget _carteSection({
    required String titre,
    required IconData icone,
    required List<Widget> enfants,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icone, color: primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  titre.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade200, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: enfants),
          ),
        ],
      ),
    );
  }

  Widget _ligneInfo({
    required IconData icone,
    required String label,
    required String valeur,
    Widget? action,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryBlue.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icone, color: primaryBlue, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valeur,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              ?action,
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.grey.shade100, height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _chargerProfil,
          ),
        ],
      ),
      drawer: construireDrawer(context),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: _chargerProfil,
              color: primaryBlue,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Avertissement si mode démo
                  if (!_estConnecte)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Mode démonstration. Connectez-vous pour accéder à votre profil officiel.',
                              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/connexion'),
                            child: const Text('Connexion', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                  // ==========================================
                  // 1. CARTE HERO PROFIL & AVATAR
                  // ==========================================
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: primaryBlue,
                              backgroundImage: (_profil?.photo != null && _profil!.photo!.startsWith('http'))
                                  ? NetworkImage(_profil!.photo!)
                                  : null,
                              child: (_profil?.photo == null || !_profil!.photo!.startsWith('http'))
                                  ? Text(
                                      _profil?.initiales ?? 'U',
                                      style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.5,
                                      ),
                                    )
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: (_profil?.actif ?? true) ? mintAccent : dangerRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _profil?.nomComplet ?? 'Utilisateur',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _profil?.email ?? 'Compte FitLife',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Badges (Rôle & Statut)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: primaryBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shield_outlined, color: Colors.white, size: 14),
                                  const SizedBox(width: 5),
                                  Text(
                                    (_profil?.roleLibelle ?? 'ATHLÈTE').toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: (_profil?.actif ?? true) ? mintAccent.withAlpha(25) : dangerRed.withAlpha(25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: (_profil?.actif ?? true) ? mintAccent : dangerRed,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (_profil?.actif ?? true) ? Icons.check_circle_outline : Icons.cancel_outlined,
                                    color: (_profil?.actif ?? true) ? mintAccent : dangerRed,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (_profil?.actif ?? true) ? 'Compte Actif' : 'Suspendu',
                                    style: TextStyle(
                                      color: (_profil?.actif ?? true) ? mintAccent : dangerRed,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Bouton Modifier
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _ouvrirDialogueModification,
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text(
                              'MODIFIER LE PROFIL',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==========================================
                  // 2. INFORMATIONS PERSONNELLES
                  // ==========================================
                  _carteSection(
                    titre: 'Informations Personnelles',
                    icone: Icons.person_outline,
                    enfants: [
                      _ligneInfo(
                        icone: Icons.badge_outlined,
                        label: 'Prénom',
                        valeur: (_profil?.prenom?.isNotEmpty ?? false) ? _profil!.prenom! : 'Non renseigné',
                      ),
                      _ligneInfo(
                        icone: Icons.person_outline,
                        label: 'Nom de famille',
                        valeur: (_profil?.nom?.isNotEmpty ?? false) ? _profil!.nom! : 'Non renseigné',
                      ),
                      _ligneInfo(
                        icone: Icons.email_outlined,
                        label: 'Adresse e-mail',
                        valeur: _profil?.email ?? 'Non renseignée',
                      ),
                      _ligneInfo(
                        icone: Icons.phone_outlined,
                        label: 'Téléphone',
                        valeur: (_profil?.telephone?.isNotEmpty ?? false) ? _profil!.telephone! : 'Non renseigné',
                      ),
                      _ligneInfo(
                        icone: Icons.wc_outlined,
                        label: 'Genre',
                        valeur: _profil?.genreLibelle ?? 'Non renseigné',
                      ),
                      _ligneInfo(
                        icone: Icons.cake_outlined,
                        label: 'Date de naissance',
                        valeur: _profil?.dateNaissance != null
                            ? '${_profil!.dateNaissanceFormatee} (${_profil!.age ?? 0} ans)'
                            : 'Non renseignée',
                        isLast: true,
                      ),
                    ],
                  ),

                  // ==========================================
                  // 3. DÉTAILS DU COMPTE & SYSTÈME
                  // ==========================================
                  _carteSection(
                    titre: 'Détails du Compte',
                    icone: Icons.fingerprint,
                    enfants: [
                      _ligneInfo(
                        icone: Icons.vpn_key_outlined,
                        label: 'Identifiant unique (UUID)',
                        valeur: _profil?.id ?? 'N/A',
                        action: IconButton(
                          icon: const Icon(Icons.copy, size: 16, color: primaryBlue),
                          tooltip: 'Copier l\'ID',
                          onPressed: () {
                            if (_profil != null) {
                              Clipboard.setData(ClipboardData(text: _profil!.id));
                              afficherMessage(context, 'Identifiant copié !');
                            }
                          },
                        ),
                      ),
                      _ligneInfo(
                        icone: Icons.calendar_month_outlined,
                        label: 'Date d\'inscription',
                        valeur: _profil?.dateCreationFormatee ?? 'Non renseignée',
                      ),
                      _ligneInfo(
                        icone: Icons.verified_user_outlined,
                        label: 'Statut du compte',
                        valeur: (_profil?.actif ?? true) ? 'Actif' : 'Inactif',
                        isLast: true,
                      ),
                    ],
                  ),

                  // ==========================================
                  // 4. ACCÈS RAPIDES
                  // ==========================================
                  _carteSection(
                    titre: 'Accès Rapides',
                    icone: Icons.dashboard_customize_outlined,
                    enfants: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: primaryBlue.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.restaurant_menu, color: primaryBlue),
                        ),
                        title: const Text('Nutrition & Suivi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Programmes, pesées et consultations', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => Navigator.pushReplacementNamed(context, '/nutrition'),
                      ),
                      Divider(color: Colors.grey.shade100, height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: primaryBlue.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.fitness_center, color: primaryBlue),
                        ),
                        title: const Text('Entraînement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Exploration musculaire, séances et programmes', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => Navigator.pushReplacementNamed(context, '/entrainement'),
                      ),
                      Divider(color: Colors.grey.shade100, height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: primaryBlue.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.event, color: primaryBlue),
                        ),
                        title: const Text('Événements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Gestion des événements et inscriptions', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => Navigator.pushReplacementNamed(context, '/evenements'),
                      ),
                    ],
                  ),

                  // ==========================================
                  // 5. BOUTON DE DÉCONNEXION
                  // ==========================================
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 24),
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await Supabase.instance.client.auth.signOut();
                        } catch (_) {}
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/connexion', (r) => false);
                        }
                      },
                      icon: const Icon(Icons.logout, size: 18, color: dangerRed),
                      label: const Text(
                        'SE DÉCONNECTER',
                        style: TextStyle(color: dangerRed, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: dangerRed),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
