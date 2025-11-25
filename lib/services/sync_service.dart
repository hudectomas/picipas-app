import 'offline_service.dart';
import 'api_service.dart';

class SyncService {
  final OfflineService _offlineService = OfflineService();

  // Synchronizovať všetky offline dáta
  Future<void> syncAll() async {
    if (!await _offlineService.isOnline()) {
      return; // Nie sme online, nemôžeme synchronizovať
    }

    await syncPoints();
    await syncHistory();
  }

  // Synchronizovať body
  Future<void> syncPoints() async {
    final unsyncedPoints = await _offlineService.getUnsyncedPoints();

    for (final point in unsyncedPoints) {
      try {
        final response = await ApiService.post('/points/add', {
          'user_id': point['user_id'],
          'drink_id': point['drink_id'],
          'quantity': point['quantity'],
          'notes': point['notes'],
        });

        if (response.statusCode == 201) {
          await _offlineService.markPointsAsSynced(point['id'] as int);
        }
      } catch (e) {
        // Chyba pri synchronizácii bodov - necháme na ďalšiu synchronizáciu
      }
    }

    // Vymazať synchronizované body
    await _offlineService.deleteSyncedPoints();
  }

  // Synchronizovať históriu
  Future<void> syncHistory() async {
    final unsyncedHistory = await _offlineService.getUnsyncedHistory();

    for (final history in unsyncedHistory) {
      try {
        // História sa synchronizuje automaticky pri pridávaní bodov
        // Toto je len pre prípad, že by sme potrebovali samostatnú synchronizáciu
        await _offlineService.markHistoryAsSynced(history['id'] as int);
      } catch (e) {
        // Chyba pri synchronizácii histórie - necháme na ďalšiu synchronizáciu
      }
    }
  }

  // Načítať cacheované dáta pri štarte
  Future<void> loadCache() async {
    // Načítať cacheované nápoje a používateľov
    // Toto sa volá pri štarte aplikácie
  }
}

