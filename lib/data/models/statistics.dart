class Statistics {
  final int totalExpense;
  final List<CategoryStat> categoryStats;

  Statistics({
    required this.totalExpense,
    required this.categoryStats,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalExpense: json['totalExpense'] as int,
      categoryStats: (json['categoryStats'] as List<dynamic>)
          .map((c) => CategoryStat.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CategoryStat {
  final String category;
  final String categoryName;
  final int amount;
  final double percentage;

  CategoryStat({
    required this.category,
    required this.categoryName,
    required this.amount,
    required this.percentage,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      category: json['category'] as String,
      categoryName: json['categoryName'] as String,
      amount: json['amount'] as int,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  String get icon {
    switch (category) {
      case 'FOOD':
        return '🍴';
      case 'ACCOMMODATION':
        return '🏨';
      case 'TRANSPORTATION':
        return '🚗';
      case 'ENTERTAINMENT':
        return '🎭';
      case 'SHOPPING':
        return '🛍️';
      case 'OTHER':
      default:
        return '📝';
    }
  }

  String get formattedAmount {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$formatted원';
  }
}
