import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thot/features/admin/domain/repositories/admin_repository.dart';
import 'package:thot/features/admin/domain/entities/report.dart';
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  throw UnimplementedError('AdminRepository provider not implemented');
});
final reportsProvider = FutureProvider<List<Report>>((ref) async {
  final repository = ref.read(adminRepositoryProvider);
  final result = await repository.getReports();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (reports) => reports,
  );
});