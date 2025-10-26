class SubscriptionModel {
  final String id;
  final String userId;
  final String subscriptionId;
  final String planId;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? nextBillingDate;
  final double amount;
  final String currency;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.planId,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.nextBillingDate,
    required this.amount,
    required this.currency,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      subscriptionId: json['subscriptionId'] ?? '',
      planId: json['planId'] ?? '',
      status: json['status'] ?? 'expired',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      nextBillingDate: json['nextBillingDate'] != null
          ? DateTime.parse(json['nextBillingDate'])
          : null,
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'subscriptionId': subscriptionId,
      'planId': planId,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'nextBillingDate': nextBillingDate?.toIso8601String(),
      'amount': amount,
      'currency': currency,
    };
  }

  bool get isActive => status == 'active' && endDate.isAfter(DateTime.now());
}
