class Review {
  final String id;
  final String author;
  final String? title;
  final String comment;
  final int rating; // 1-5
  final DateTime date;
  final String? profilePicture;
  final bool hasOwnerResponse;
  final String? ownerResponse;
  final DateTime? ownerResponseDate;
  final int helpfulCount;

  const Review({
    required this.id,
    required this.author,
    this.title,
    required this.comment,
    required this.rating,
    required this.date,
    this.profilePicture,
    this.hasOwnerResponse = false,
    this.ownerResponse,
    this.ownerResponseDate,
    this.helpfulCount = 0,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final dynamic rawRating = json['overall_rating'] ?? json['rating'];
    final firstName = json['first_name'] as String? ?? '';
    final lastName = json['last_name'] as String? ?? '';
    final author = '$firstName $lastName'.trim();

    return Review(
      id: '${json['id']}',
      author: author.isNotEmpty
          ? author
          : (json['author'] as String? ?? 'Utilisateur'),
      title: json['title'] as String?,
      comment: json['content'] as String? ?? json['comment'] as String? ?? '',
      rating: rawRating is int ? rawRating : int.tryParse('$rawRating') ?? 0,
      date:
          DateTime.tryParse(
            json['created_at'] as String? ?? json['date'] as String? ?? '',
          ) ??
          DateTime.now(),
      profilePicture: json['profile_picture'] as String?,
      hasOwnerResponse:
          json['has_owner_response'] == true ||
          json['has_owner_response'] == 1 ||
          '${json['has_owner_response']}'.toLowerCase() == 'true',
      ownerResponse: json['owner_response'] as String?,
      ownerResponseDate: DateTime.tryParse(
        json['owner_response_date'] as String? ?? '',
      ),
      helpfulCount: json['helpful_count'] is int
          ? json['helpful_count'] as int
          : int.tryParse('${json['helpful_count']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      if (title != null) 'title': title,
      'comment': comment,
      'rating': rating,
      'date': date.toIso8601String(),
      if (profilePicture != null) 'profile_picture': profilePicture,
      'has_owner_response': hasOwnerResponse,
      if (ownerResponse != null) 'owner_response': ownerResponse,
      if (ownerResponseDate != null)
        'owner_response_date': ownerResponseDate!.toIso8601String(),
      'helpful_count': helpfulCount,
    };
  }

  Review copyWith({
    String? id,
    String? author,
    String? title,
    String? comment,
    int? rating,
    DateTime? date,
    String? profilePicture,
    bool? hasOwnerResponse,
    String? ownerResponse,
    DateTime? ownerResponseDate,
    int? helpfulCount,
  }) {
    return Review(
      id: id ?? this.id,
      author: author ?? this.author,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      rating: rating ?? this.rating,
      date: date ?? this.date,
      profilePicture: profilePicture ?? this.profilePicture,
      hasOwnerResponse: hasOwnerResponse ?? this.hasOwnerResponse,
      ownerResponse: ownerResponse ?? this.ownerResponse,
      ownerResponseDate: ownerResponseDate ?? this.ownerResponseDate,
      helpfulCount: helpfulCount ?? this.helpfulCount,
    );
  }

  /// Format date to relative time (e.g., "Il y a 2 jours")
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'À l\'instant';
        }
        return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
      }
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
  }
}
