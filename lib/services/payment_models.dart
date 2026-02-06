/// Payment result status enum
enum PaymentStatus { pending, success, failed, cancelled }

/// Payment request model for initiating a payment
class PaymentRequest {
  final double amount;
  final String currency;
  final String itemRef;
  final String paymentRef;
  final String userId;
  final String userEmail;
  final String? userPhone;
  final String? firstName;
  final String? lastName;
  final String returnUrl;
  final String notifyUrl;

  PaymentRequest({
    required this.amount,
    required this.currency,
    required this.itemRef,
    required this.paymentRef,
    required this.userId,
    required this.userEmail,
    this.userPhone,
    this.firstName,
    this.lastName,
    required this.returnUrl,
    required this.notifyUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'currency': currency,
      'item_ref': itemRef,
      'payment_ref': paymentRef,
      'user': userId,
      'email': userEmail,
      if (userPhone != null) 'phone': userPhone,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      'return_url': returnUrl,
      'notify_url': notifyUrl,
      'locale': 'en', // Can be 'en' or 'fr'
    };
  }
}

/// Payment transaction model for database storage
class PaymentTransaction {
  final String id;
  final String userId;
  final String paymentRef;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String? departmentId;
  final String? materialId;
  final String itemType; // 'department' or 'material'
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentTransaction({
    required this.id,
    required this.userId,
    required this.paymentRef,
    required this.amount,
    required this.currency,
    required this.status,
    this.departmentId,
    this.materialId,
    required this.itemType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentTransaction.fromSupabase(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      paymentRef: json['payment_ref'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: _parsePaymentStatus(json['status'] as String),
      departmentId: json['department_id'] as String?,
      materialId: json['material_id'] as String?,
      itemType: json['item_type'] as String? ?? 'department',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'payment_ref': paymentRef,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      if (departmentId != null) 'department_id': departmentId,
      if (materialId != null) 'material_id': materialId,
      'item_type': itemType,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static PaymentStatus _parsePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return PaymentStatus.success;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  PaymentTransaction copyWith({
    String? id,
    String? userId,
    String? paymentRef,
    double? amount,
    String? currency,
    PaymentStatus? status,
    String? departmentId,
    String? materialId,
    String? itemType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      paymentRef: paymentRef ?? this.paymentRef,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      departmentId: departmentId ?? this.departmentId,
      materialId: materialId ?? this.materialId,
      itemType: itemType ?? this.itemType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
