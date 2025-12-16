-- إعداد قاعدة البيانات الحقيقية لمطعم أهلنا داقوق
-- Real Supabase Database Setup for Ahlna Daquq Restaurant

-- 1. إنشاء جدول الأصناف (Food Categories)
CREATE TABLE IF NOT EXISTS public.categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    name_ar TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. إنشاء جدول الأصناف (Food Items)
CREATE TABLE IF NOT EXISTS public.food_items (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    name_ar TEXT NOT NULL,
    description TEXT,
    description_ar TEXT,
    price DECIMAL(10,2) NOT NULL,
    category_id INTEGER REFERENCES public.categories(id),
    image_url TEXT,
    is_available BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    preparation_time INTEGER DEFAULT 15,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. إنشاء جدول الطلبات (Orders)
CREATE TABLE IF NOT EXISTS public.orders (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    customer_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    address TEXT NOT NULL,
    order_type TEXT NOT NULL DEFAULT 'delivery',
    status TEXT NOT NULL DEFAULT 'pending',
    total_price DECIMAL(10,2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. إنشاء جدول تفاصيل الطلبات (Order Items)
CREATE TABLE IF NOT EXISTS public.order_items (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    order_id TEXT REFERENCES public.orders(id) ON DELETE CASCADE,
    food_item_id TEXT REFERENCES public.food_items(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. إضافة البيانات الحقيقية (Real Data)

-- إضافة الأصناف (Categories)
INSERT INTO public.categories (id, name, name_ar, description, image_url, sort_order) VALUES 
(1, 'Lahm Bi Ajeen', 'لحم بعجين', 'عجينة رقيقة مع لحم متبل', 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=1080&auto=format&fit=crop', 1),
(2, 'Pizza', 'بيتزا', 'بيتزا طازجة بمكونات مميزة', 'https://images.unsplash.com/photo-1601924582971-b0c2a5fb7f63?q=80&w=1080&auto=format&fit=crop', 2),
(3, 'Drinks', 'مشروبات', 'مشروبات طازجة ومنعشة', 'https://images.unsplash.com/photo-1488900128323-21503983a07e?q=80&w=1080&auto=format&fit=crop', 3);

-- إضافة الأصناف (Food Items)
INSERT INTO public.food_items (id, name, name_ar, description, description_ar, price, category_id, image_url, preparation_time) VALUES 
('1', 'Lahm Bi Ajeen Classic', 'لحم بعجين كلاسيكي', 'Thin dough with specially seasoned meat from Ahlna Daquq', 'عجينة رقيقة مع لحم متبل بطريقة أهلنا داقوق', 2.50, 1, 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=1080&auto=format&fit=crop', 10),
('2', 'Lahm Bi Ajeen Spicy', 'لحم بعجين حار', 'Spicy flavor with special sauce', 'نكهة حارة مع صوص خاص', 2.75, 1, 'https://images.unsplash.com/photo-1541599184141-22d5009251d1?q=80&w=1080&auto=format&fit=crop', 10),
('3', 'Margherita Pizza', 'بيتزا مارغريتا', 'Fresh pizza with mozzarella cheese and Italian herbs', 'بيتزا طازجة بجبن الموزاريلا وباذوق إيطالي', 5.00, 2, 'https://images.unsplash.com/photo-1601924582971-b0c2a5fb7f63?q=80&w=1080&auto=format&fit=crop', 15),
('4', 'Pepperoni Pizza', 'بيتزا بيبروني', 'Smoked pepperoni on crispy dough', 'بيبروني مدخن على عجينة مقرمشة', 6.00, 2, 'https://images.unsplash.com/photo-1566843970350-1f3143b1c99b?q=80&w=1080&auto=format&fit=crop', 15),
('5', 'Fresh Lemonade', 'ليمونادة طازجة', 'Refreshing natural lemon drink', 'مشروب ليمون منعش طبيعي', 1.50, 3, 'https://images.unsplash.com/photo-1488900128323-21503983a07e?q=80&w=1080&auto=format&fit=crop', 2),
('6', 'Iraqi Tea', 'شاي عراقي', 'Strong Iraqi tea with cardamom', 'شاي عراقي ثقيل مع الهيل', 1.00, 3, 'https://images.unsplash.com/photo-1513639729370-97597a5b9d97?q=80&w=1080&auto=format&fit=crop', 3);

-- 6. إنشاء السياسات (Policies)

-- السماح للجميع بقراءة الأصناف والأصناف
CREATE POLICY "public_read_categories" ON public.categories
    FOR SELECT USING (true);

CREATE POLICY "public_read_food_items" ON public.food_items
    FOR SELECT USING (is_available = true);

-- السماح للمستخدمين المجهولين بإنشاء طلبات
CREATE POLICY "anon_insert_orders" ON public.orders
    FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon_select_orders" ON public.food_items
    FOR SELECT TO anon USING (true);

-- السماح بقراءة تفاصيل الطلبات
CREATE POLICY "anon_read_order_items" ON public.order_items
    FOR SELECT TO anon USING (true);

-- 7. تمكين RLS (Row Level Security)
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- 8. إنشاء فهرس للبحث السريع
CREATE INDEX IF NOT EXISTS idx_food_items_category ON public.food_items(category_id);
CREATE INDEX IF NOT EXISTS idx_food_items_available ON public.food_items(is_available);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items(order_id);

-- 9. إنشاء دالة لتحديث وقت التعديل
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 10. إنشاء triggers لتحديث أعمدة updated_at
CREATE TRIGGER update_food_items_updated_at BEFORE UPDATE ON public.food_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 11. إنشاء جدول العروضات (Offers)
CREATE TABLE IF NOT EXISTS public.offers (
    id TEXT PRIMARY KEY,
    url TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- سياسات القراءة والكتابة للعروضات
CREATE POLICY IF NOT EXISTS "public_read_offers" ON public.offers
    FOR SELECT USING (true);

CREATE POLICY IF NOT EXISTS "anon_upsert_offers" ON public.offers
    FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "anon_update_offers" ON public.offers
    FOR UPDATE TO anon USING (true) WITH CHECK (true);

ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;

-- 12. جدول سجل الطلبات (Order Records)
CREATE TABLE IF NOT EXISTS public.order_records (
    id TEXT PRIMARY KEY,
    customer_name TEXT,
    phone TEXT,
    address TEXT,
    order_type TEXT,
    status TEXT,
    total_price DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE POLICY IF NOT EXISTS "public_read_order_records" ON public.order_records
    FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS "anon_insert_order_records" ON public.order_records
    FOR INSERT TO anon WITH CHECK (true);
ALTER TABLE public.order_records ENABLE ROW LEVEL SECURITY;

-- 13. سياسات تحديث/حذف على الطلبات لتطبيق الأدمن (للاختبار)
-- تحذير: هذه السياسات تسمح للمجهول بالتحديث/الحذف. يُستحسن استخدام Service Role
-- في الإنتاج. يمكن تعطيلها لاحقاً.
CREATE POLICY IF NOT EXISTS "anon_update_orders" ON public.orders
    FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY IF NOT EXISTS "anon_delete_orders" ON public.orders
    FOR DELETE TO anon USING (true);
CREATE POLICY IF NOT EXISTS "anon_update_order_items" ON public.order_items
    FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY IF NOT EXISTS "anon_delete_order_items" ON public.order_items
    FOR DELETE TO anon USING (true);

-- 14. جدول الملف الشخصي (Profiles)
CREATE TABLE IF NOT EXISTS public.profiles (
    user TEXT PRIMARY KEY,
    phone TEXT UNIQUE,
    name TEXT,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE POLICY IF NOT EXISTS "auth_read_own_profile" ON public.profiles
    FOR SELECT TO authenticated USING (user = auth.uid()::text);

CREATE POLICY IF NOT EXISTS "auth_upsert_own_profile" ON public.profiles
    FOR INSERT TO authenticated WITH CHECK (user = auth.uid()::text);

CREATE POLICY IF NOT EXISTS "auth_update_own_profile" ON public.profiles
    FOR UPDATE TO authenticated USING (user = auth.uid()::text) WITH CHECK (user = auth.uid()::text);

CREATE POLICY IF NOT EXISTS "anon_upsert_profiles" ON public.profiles
    FOR INSERT TO anon WITH CHECK (user = phone AND phone IS NOT NULL);

CREATE POLICY IF NOT EXISTS "anon_update_profiles" ON public.profiles
    FOR UPDATE TO anon USING (user = phone) WITH CHECK (user = phone);

CREATE POLICY IF NOT EXISTS "anon_select_profiles" ON public.profiles
    FOR SELECT TO anon USING (true);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
