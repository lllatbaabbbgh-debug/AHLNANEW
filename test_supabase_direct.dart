import 'package:supabase/supabase.dart';

void main() async {
  print('🧪 Testing Supabase order_records functionality...');
  
  final supabase = SupabaseClient(
    'https://boylzidmvvldouxtrpiv.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY',
  );
  
  try {
    // Test 1: Check if we can connect and fetch orders
    print('\n📋 Testing connection and fetching orders...');
    final orders = await supabase.from('orders').select('*').neq('status', 'completed');
    print('✅ Found ${orders.length} active orders');
    
    if (orders.isNotEmpty) {
      final testOrder = orders.first;
      print('📝 Testing with order: ${testOrder['id']}');
      print('   Customer: ${testOrder['customer_name']}');
      print('   Status: ${testOrder['status']}');
      
      // Test 2: Try to complete an order (move to records)
      print('\n🎯 Testing complete functionality...');
      
      // First, let's check the structure of order_records table
      print('\n📊 Checking order_records table structure...');
      try {
        final records = await supabase.from('order_records').select('*').limit(1);
        print('✅ order_records table accessible, found ${records.length} sample records');
        
        if (records.isNotEmpty) {
          print('📋 Sample record structure:');
          records.first.forEach((key, value) {
            print('   $key: $value');
          });
        }
      } catch (e) {
        print('⚠️ Could not access order_records table: $e');
      }
      
      // Now try to move the order to records
      print('\n🔄 Attempting to move order to records...');
      
      try {
        // Get order items first
        final orderItems = await supabase.from('order_items').select('*').eq('order_id', testOrder['id']);
        print('📋 Found ${orderItems.length} items for this order');
        
        // Create record data
        final recordData = {
          'id': testOrder['id'],
          'customer_name': testOrder['customer_name'],
          'phone': testOrder['phone'],
          'address': testOrder['address'],
          'status': 'completed',
          'total_price': testOrder['total_price'],
          'created_at': testOrder['created_at'],
        };
        
        // Try with order_type if available
        if (testOrder['order_type'] != null) {
          recordData['order_type'] = testOrder['order_type'];
        }
        
        print('📤 Inserting into order_records...');
        await supabase.from('order_records').insert(recordData);
        print('✅ Successfully inserted into order_records');
        
        // Delete from orders
        print('🗑️ Deleting from orders table...');
        await supabase.from('order_items').delete().eq('order_id', testOrder['id']);
        await supabase.from('orders').delete().eq('id', testOrder['id']);
        print('✅ Successfully deleted from orders table');
        
        // Verify the move
        print('\n✅ Verification - checking if order moved successfully...');
        final movedRecord = await supabase.from('order_records').select('*').eq('id', testOrder['id']);
        if (movedRecord.isNotEmpty) {
          print('🎉 SUCCESS! Order successfully moved to records!');
          print('   Record ID: ${movedRecord.first['id']}');
          print('   Status: ${movedRecord.first['status']}');
          print('   Completed at: ${movedRecord.first['completed_at']}');
        } else {
          print('❌ Order not found in records after move');
        }
        
      } catch (e) {
        print('❌ Error during order completion: $e');
        
        // Try fallback - just update status in orders table
        print('\n🔄 Fallback: trying to just update status in orders table...');
        try {
          await supabase.from('orders').update({'status': 'completed'}).eq('id', testOrder['id']);
          print('✅ Successfully updated status to completed in orders table');
        } catch (fallbackError) {
          print('❌ Fallback also failed: $fallbackError');
        }
      }
      
    } else {
      print('⚠️ No active orders found to test with');
      
      // Create a test order
      print('\n📝 Creating test order...');
      final testOrderId = DateTime.now().millisecondsSinceEpoch.toString();
      final testOrderData = {
        'id': testOrderId,
        'customer_name': 'Test Customer',
        'phone': '07701234567',
        'address': 'Test Address',
        'order_type': 'delivery',
        'status': 'pending',
        'total_price': 100.0,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      try {
        await supabase.from('orders').insert(testOrderData);
        print('✅ Test order created: $testOrderId');
        
        // Now test completing it
        print('\n🎯 Testing complete on new order...');
        
        final recordData = {
          'id': testOrderId,
          'customer_name': 'Test Customer',
          'phone': '07701234567',
          'address': 'Test Address',
          'order_type': 'delivery',
          'status': 'completed',
          'total_price': 100.0,
          'created_at': testOrderData['created_at'],
        };
        
        await supabase.from('order_records').insert(recordData);
        await supabase.from('orders').delete().eq('id', testOrderId);
        
        print('✅ Test order successfully moved to records!');
        
      } catch (e) {
        print('❌ Error with test order: $e');
      }
    }
    
  } catch (e, stackTrace) {
    print('❌ Error during testing: $e');
    print('Stack trace: $stackTrace');
  }
  
  print('\n🧪 Test completed!');
}