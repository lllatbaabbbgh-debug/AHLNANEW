import 'lib/core/supabase_client.dart';
import 'lib/core/repos/order_repository.dart';

void main() async {
  print('🧪 Testing order_records functionality...');
  
  // Initialize Supabase with service role key
  await SupabaseManager.initialize(
    url: 'https://boylzidmvvldouxtrpiv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4NDQ0NjgsImV4cCI6MjA3OTQyMDQ2OH0.k-YInG1GfcBK6GQCjOuGMYcP_m2Eq7yTQSPuspCExr0',
    serviceRoleKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY',
  );
  
  final repo = OrderRepository();
  
  try {
    // Test 1: Check if we can fetch orders
    print('\n📋 Testing fetch orders...');
    final orders = await repo.fetchActiveOrders();
    print('✅ Found ${orders.length} active orders');
    
    if (orders.isNotEmpty) {
      final testOrder = orders.first;
      print('📝 Testing with order: ${testOrder.id}');
      print('   Customer: ${testOrder.customerName}');
      print('   Status: ${testOrder.status}');
      
      // Test 2: Try to complete an order
      print('\n🎯 Testing complete functionality...');
      await repo.setStatus(testOrder.id, 'completed');
      print('✅ Order marked as completed');
      
      // Test 3: Check if order moved to records
      print('\n📊 Checking order_records...');
      final records = await repo.fetchRecords();
      print('✅ Found ${records.length} records');
      
      // Look for our completed order
      final completedRecord = records.firstWhere(
        (r) => r['id'] == testOrder.id,
        orElse: () => {},
      );
      
      if (completedRecord.isNotEmpty) {
        print('✅ Order successfully moved to records!');
        print('   Record ID: ${completedRecord['id']}');
        print('   Status: ${completedRecord['status']}');
        print('   Completed at: ${completedRecord['completed_at']}');
      } else {
        print('❌ Order not found in records table');
      }
    } else {
      print('⚠️ No active orders found to test with');
      
      // Test creating a dummy order for testing
      print('\n📝 Creating test order...');
      final orderId = await repo.createOrder(
        customerName: 'Test Customer',
        phone: '07701234567',
        address: 'Test Address',
        orderType: 'delivery',
        items: [],
      );
      
      if (orderId != null) {
        print('✅ Test order created: $orderId');
        
        // Now try to complete it
        print('\n🎯 Testing complete on new order...');
        await repo.setStatus(orderId, 'completed');
        print('✅ Test order marked as completed');
        
        // Check records
        final records = await repo.fetchRecords();
        final testRecord = records.firstWhere(
          (r) => r['id'] == orderId,
          orElse: () => {},
        );
        
        if (testRecord.isNotEmpty) {
          print('✅ Test order successfully moved to records!');
        } else {
          print('❌ Test order not found in records');
        }
      }
    }
    
  } catch (e, stackTrace) {
    print('❌ Error during testing: $e');
    print('Stack trace: $stackTrace');
  }
  
  print('\n🧪 Test completed!');
}