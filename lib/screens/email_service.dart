import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendOrderToSeller({
  required String toEmail,
  required String sellerName,
  required String orderId,
  required List<Map<String, dynamic>> orders,
  required Map<String, dynamic> cost,
  required String buyerAddress,
  required String buyerContact,
}) async {
  const serviceId = 'bookswap09';
  const templateId = 'template_3c9c5ct'; // Seller template
  const publicKey = 'SHjWAohaiMM8dG0SE';

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
  final response = await http.post(
    url,
    headers: {'origin': 'http://localhost', 'Content-Type': 'application/json'},
    body: jsonEncode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': publicKey,
      'template_params': {
        'seller_email': toEmail,
        'seller_name': sellerName,
        'order_id': orderId,
        'orders': orders,
        'cost': cost,
        'buyer_address': buyerAddress,
        'buyer_contact': buyerContact,
      },
    }),
  );

  if (response.statusCode == 200) {
    print('✅ Seller Email sent');
  } else {
    print('❌ Failed to send seller email: ${response.body}');
  }
}

Future<void> sendOrderToBuyer({
  required String toEmail,
  required String buyerName,
  required String orderId,
  required List<Map<String, dynamic>> orders,
  required Map<String, dynamic> cost,
  required String shippingAddress,
}) async {
  const serviceId = 'bookswap09';
  const templateId = 'ebt0hq8'; // replace with actual buyer template ID
  const publicKey = 'SHjWAohaiMM8dG0SE';

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

  final response = await http.post(
    url,
    headers: {'origin': 'http://localhost', 'Content-Type': 'application/json'},
    body: jsonEncode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': publicKey,
      'template_params': {
        'buyer_email': toEmail,
        'buyer_name': buyerName,
        'order_id': orderId,
        'orders': orders,
        'cost': cost,
        'shipping_address': shippingAddress,
      },
    }),
  );

  if (response.statusCode == 200) {
    //print('✅ Email sent to buyer');
  } else {
    //print('❌ Failed to send to buyer: ${response.body}');
  }
}
