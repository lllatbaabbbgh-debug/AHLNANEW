import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_item.dart';
import 'sample_data.dart';

class SupabaseConfig {
  // Development configuration - using local mock data
  static const supabaseUrl = 'https://localhost:54321';
  static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvY2FsaG9zdCIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzAwMDAwMDAwLCJleHAiOjE3MjU1NzYwMDB9.mock-key-for-development';
  static const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvY2FsaG9zdCIsInJvbGUiOiJzZXJ2aWNlX3JvbGUiLCJpYXQiOjE3MDAwMDAwMDAsImV4cCI6MTcyNTU3NjAwMH0.mock-service-key-for-development';
}

class SupabaseManager {
  static bool _initialized = false;
  static final bool _useMockData = true; // Use mock data for development
  
  static Future<void> init() async {
    if (_initialized) return;
    
    if (_useMockData) {
      print('🚀 Running in development mode with mock data');
      print('📋 Loaded ${sampleFoodItems.length} sample food items');
      _initialized = true;
      return;
    }
    
    // Real Supabase initialization
    final url = SupabaseConfig.supabaseUrl;
    final key = SupabaseConfig.supabaseAnonKey;
    
    print('🔑 Supabase URL: ${url.isNotEmpty ? "${url.substring(0, 20)}..." : "EMPTY"}');
    print('🔑 Supabase Key: ${key.isNotEmpty ? "${key.substring(0, 10)}..." : "EMPTY"}');
    
    if (url.isEmpty || key.isEmpty) {
      print('❌ Supabase credentials are empty!');
      _initialized = true;
      return;
    }
    
    await Supabase.initialize(url: url, anonKey: key);
    _initialized = true;
  }
  
  static SupabaseClient? get client {
    if (_useMockData) {
      return null; // Return null to indicate mock mode
    }
    return Supabase.instance.client;
  }
  
  static bool get isMockMode => _useMockData;
  
  static Future<List<FoodItem>> getFoodItemsByCategory(String category) async {
    if (_useMockData) {
      // Return mock data based on category
      return sampleFoodItems.where((item) => item.category == category).toList();
    }
    
    // Real Supabase query
    final response = await client!
        .from('food_items')
        .select('*')
        .eq('category', category)
        .order('name', ascending: false);
    
    return (response as List).map((item) => FoodItem.fromJson(item)).toList();
  }
  
  static Future<List<FoodItem>> getAllFoodItems() async {
    if (_useMockData) {
      return sampleFoodItems;
    }
    
    // Real Supabase query
    final response = await client!
        .from('food_items')
        .select('*')
        .order('name', ascending: false);
    
    return (response as List).map((item) => FoodItem.fromJson(item)).toList();
  }
  
  static Future<List<FoodItem>> getFeaturedFoodItems() async {
    if (_useMockData) {
      return sampleFoodItems.where((item) => item.id == '1' || item.id == '3').toList();
    }
    
    // Real Supabase query
    final response = await client!
        .from('food_items')
        .select('*')
        .eq('is_featured', true)
        .order('name', ascending: false);
    
    return (response as List).map((item) => FoodItem.fromJson(item)).toList();
  }
}