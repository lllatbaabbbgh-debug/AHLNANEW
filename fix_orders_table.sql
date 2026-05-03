-- التحقق من أعمدة جدول orders وإضافة العمود المفقود
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS order_type text;

-- التحقق من جميع الأعمدة المطلوبة
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS customer_name text,
ADD COLUMN IF NOT EXISTS phone text,
ADD COLUMN IF NOT EXISTS address text,
ADD COLUMN IF NOT EXISTS order_type text,
ADD COLUMN IF NOT EXISTS status text,
ADD COLUMN IF NOT EXISTS total_price numeric(10,2),
ADD COLUMN IF NOT EXISTS created_at timestamp with time zone;