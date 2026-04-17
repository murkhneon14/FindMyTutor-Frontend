class SubscriptionModel {
  final String id;
  final String userId;
  final String orderId;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String currency;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.currency,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      orderId: json['orderId'] ?? '',
      status: json['status'] ?? 'expired',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'orderId': orderId,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'amount': amount,
      'currency': currency,
    };
  }

  bool get isActive => status == 'active' && endDate.isAfter(DateTime.now());

  int get daysRemaining {
    if (!isActive) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }
}
