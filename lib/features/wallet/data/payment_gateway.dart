/// Payment Gateway Abstraction — bKash / Nagad / Card
/// ⚠️ স্বচ্ছতা: এখানে DemoGateway আছে যাতি পুরো flow এখনই টেস্ট করা যায়।
/// Production-এ SSLCommerz/aamarPay ইন্টিগ্রেশন:
///   ১. Gateway-এর SDK দিয়ে payment initiate করুন
///   ২. Gateway server-এ IPN/callback পাঠাবে
///   ৩. Supabase Edge Function signature verify করে verify_payment RPC call করবে
abstract class PaymentGateway {
  Future<GatewayResult> pay({
    required String paymentId,
    required String method,     // bkash | nagad | card
    required int amountBdt,
    required String purpose,
  });
}

class GatewayResult {
  final bool success;
  final String? trxId, error;
  const GatewayResult.success(this.trxId) : success = true, error = null;
  const GatewayResult.failed(this.error) : success = false, trxId = null;
}

/// 🧪 Demo gateway — আসল টাকা লেনদেন করে না, flow সিমিউলেট করে
class DemoGateway implements PaymentGateway {
  @override
  Future<GatewayResult> pay({
    required String paymentId, required String method,
    required int amountBdt, required String purpose,
  }) async {
    // আসল gateway হলে এখানে redirect/SDK call হতো
    await Future.delayed(const Duration(seconds: 2));
    return GatewayResult.success('DEMO_$paymentId');
  }
}