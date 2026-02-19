class RegionalFood {
  final int id;
  final String foodName;
  final String accountName;
  final int accountId;
  final String description;
  final String url;
  final bool isLiked;

  const RegionalFood({
    required this.id,
    required this.foodName,
    required this.accountName,
    required this.accountId,
    required this.description,
    required this.isLiked,
    required this.url,
  });
}
