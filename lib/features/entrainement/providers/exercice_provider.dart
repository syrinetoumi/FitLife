import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/exercice.dart';
import '../data/repositories/exercice_repository.dart';

final exerciceRepositoryProvider = Provider<ExerciceRepository>(
      (ref) => ExerciceRepository(Supabase.instance.client),
);

final exercicesParMuscleProvider =
FutureProvider.family<List<Exercice>, String>((ref, muscle) {
  return ref.watch(exerciceRepositoryProvider).parMuscle(muscle);
});