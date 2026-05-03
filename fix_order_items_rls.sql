-- حذف السياسات الموجودة إن وجدت
drop policy if exists "anon insert order_items" on public.order_items;
drop policy if exists "anon select order_items" on public.order_items;
drop policy if exists "anon update order_items" on public.order_items;
drop policy if exists "anon delete order_items" on public.order_items;

-- إنشاء سياسات جديدة لجدول order_items
create policy "anon insert order_items" on public.order_items
  for insert to anon
  with check (true);

create policy "anon select order_items" on public.order_items
  for select to anon
  using (true);

create policy "anon update order_items" on public.order_items
  for update to anon
  using (true)
  with check (true);

create policy "anon delete order_items" on public.order_items
  for delete to anon
  using (true);

-- التحقق من أن جدول order_items يحتوي على الأعمدة الصحيحة
-- يجب أن يحتوي على: order_id, food_id, name, price, quantity
ALTER TABLE public.order_items 
ADD COLUMN IF NOT EXISTS order_id text,
ADD COLUMN IF NOT EXISTS food_id text,
ADD COLUMN IF NOT EXISTS name text,
ADD COLUMN IF NOT EXISTS price numeric(10,2),
ADD COLUMN IF NOT EXISTS quantity integer;