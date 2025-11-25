-- الأوامر الحقيقية التي يجب تنفيذها في Supabase لإصلاح المشكلة

-- 1. أولاً، دعنا نرى هيكل الجدول الحالي
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. إضافة العمود المفقود 'order_type' إذا لم يكن موجوداً
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS order_type text;

-- 3. التأكد من وجود جميع الأعمدة المطلوبة
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS id text PRIMARY KEY,
ADD COLUMN IF NOT EXISTS customer_name text,
ADD COLUMN IF NOT EXISTS phone text,
ADD COLUMN IF NOT EXISTS address text,
ADD COLUMN IF NOT EXISTS order_type text,
ADD COLUMN IF NOT EXISTS status text,
ADD COLUMN IF NOT EXISTS total_price numeric(10,2),
ADD COLUMN IF NOT EXISTS created_at timestamp with time zone;

-- 4. التحقق من السياسات
SELECT * FROM pg_policies WHERE tablename = 'orders';

-- 5. إعادة إنشاء السياسات إذا لزم الأمر
drop policy if exists "anon insert orders" on public.orders;
drop policy if exists "anon select orders" on public.orders;

create policy "anon insert orders" on public.orders
  for insert to anon with check (true);

create policy "anon select orders" on public.orders
  for select to anon using (true);