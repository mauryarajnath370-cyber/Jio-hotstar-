import 'dart:convert';
import 'package:http/http.dart' as http;

class FamPayService {
  static const String apiKey = "fam_a8f0749e1f50f29e8d4d4cace23a49ed1d4fdc92";
  static const String baseUrl = "https://famgateway.in/api";

  static Future<Map<String, dynamic>?> createOrder(double amount, String name, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-order'),
        headers: {
          "Content-Type": "application/json",
          "X-Api-Key": apiKey,
        },
        body: jsonEncode({
          "amount": amount,
          "customer_name": name,
          "customer_email": email,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        // FamGateway returns: { "status": "success", "data": { "order_id": "...", "qr_url": "...", "upi_intent": "..." } }
        if (body['data'] is Map<String, dynamic>) {
          return body['data'] as Map<String, dynamic>;
        }
        return body; // Fallback if fields are at root
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String> checkStatus(String orderId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/checkout-status.php?order_id=$orderId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['status']; // "pending" or "success"
      }
      return "error";
    } catch (e) {
      return "error";
    }
  }
}
