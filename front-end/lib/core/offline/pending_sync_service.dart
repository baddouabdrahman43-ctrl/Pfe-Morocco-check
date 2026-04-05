import 'pending_checkin_service.dart';
import 'pending_review_service.dart';
import 'pending_site_submission_service.dart';

class PendingSyncService {
  PendingSyncService._();

  static final PendingSyncService instance = PendingSyncService._();

  Future<void> syncAll() async {
    await PendingCheckinService().syncPendingCheckins();
    await PendingReviewService().syncPendingReviews();
    await PendingSiteSubmissionService().syncPendingSubmissions();
  }
}
