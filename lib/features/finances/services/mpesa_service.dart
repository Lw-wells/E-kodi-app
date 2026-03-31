import 'package:cloud_functions/cloud_functions.dart';

class MpesaService {
  final _functions = FirebaseFunctions.instance;

  /// Triggers STK Push on tenant's phone.
  /// [phone] — tenant's phone e.g. "0712345678"
  /// [amount] — amount in KES
  Future<Map<String, dynamic>> triggerStkPush({
    required String phone,
    required double amount,
    required String tenantId,
    required String tenantName,
    required String unitName,
  }) async {
    final callable = _functions.httpsCallable('stkPush');
    final result   = await callable.call({
      'phone':      phone,
      'amount':     amount,
      'tenantId':   tenantId,
      'tenantName': tenantName,
      'unitName':   unitName,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}