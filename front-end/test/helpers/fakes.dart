import 'package:mor_che_frontend/core/network/api_service.dart';
import 'package:mor_che_frontend/features/auth/domain/auth_repository.dart';
import 'package:mor_che_frontend/features/profile/presentation/models/leaderboard_entry.dart';
import 'package:mor_che_frontend/features/sites/presentation/models/site_photo.dart';
import 'package:mor_che_frontend/features/sites/presentation/sites/site.dart';
import 'package:mor_che_frontend/shared/models/user.dart';

class FakeAuthRepository implements AuthRepository {
  final User? currentUser;

  FakeAuthRepository({this.currentUser});

  @override
  Future<User?> getCurrentUser() async => currentUser;

  @override
  Future<User> login(String email, String password) async {
    if (currentUser != null) {
      return currentUser!;
    }
    throw UnimplementedError();
  }

  @override
  Future<User> loginWithGoogle() async {
    if (currentUser != null) {
      return currentUser!;
    }
    throw UnimplementedError();
  }

  @override
  Future<User> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    if (currentUser != null) {
      return currentUser!;
    }
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}
}

class FakeApiService extends ApiService {
  final PaginatedResult<LeaderboardEntry>? leaderboardResult;
  final Site? siteDetail;
  final List<SitePhoto>? sitePhotos;

  FakeApiService({this.leaderboardResult, this.siteDetail, this.sitePhotos});

  @override
  Future<PaginatedResult<LeaderboardEntry>> fetchLeaderboard({
    int page = 1,
    int limit = 20,
  }) async {
    return leaderboardResult ??
        const PaginatedResult<LeaderboardEntry>(
          items: <LeaderboardEntry>[],
          page: 1,
          limit: 20,
          total: 0,
        );
  }

  @override
  Future<Site> fetchSiteDetail(String siteId) async {
    if (siteDetail != null) {
      return siteDetail!;
    }
    throw ApiException(message: 'Site introuvable', statusCode: 404);
  }

  @override
  Future<List<SitePhoto>> fetchSitePhotos(
    String siteId, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return sitePhotos ?? const <SitePhoto>[];
  }
}
