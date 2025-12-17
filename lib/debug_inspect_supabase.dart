import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  const supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4NDQ0NjgsImV4cCI6MjA3OTQyMDQ2OH0.k-YInG1GfcBK6GQCjOuGMYcP_m2Eq7yTQSPuspCExr0';

  final url = Uri.parse('$supabaseUrl/rest/v1/profiles?select=*&limit=1');
  final response = await http.get(
    url,
    headers: {'apikey': supabaseKey, 'Authorization': 'Bearer $supabaseKey'},
  );

  print('Status Code: ${response.statusCode}');
  print('Response Body: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data.isNotEmpty) {
      print('Columns found: ${data[0].keys.toList()}');
      print('First row: ${data[0]}');
    } else {
      print('Table is empty');
    }
  }
}
