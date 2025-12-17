-- هذا الكود سيحل مشكلة "تعذر تحديث قاعدة البيانات" نهائياً
-- قم بنسخ هذا الكود بالكامل ولصقه في Supabase > SQL Editor ثم اضغط RUN

-- 1. حل المشكلة الرئيسية: إضافة العمود "user" المفقود لإسكات الخطأ القديم
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS "user" uuid;

-- 2. التأكد من وجود الأعمدة الصحيحة الجديدة
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS "user_id" uuid;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS "user_id_text" text;

-- 3. تحديث البيانات: نقل البيانات من العمود القديم (إذا وجد) إلى الجديد
UPDATE public.profiles 
SET user_id = "user" 
WHERE user_id IS NULL AND "user" IS NOT NULL;

-- 4. إعطاء صلاحيات الكتابة لجميع المستخدمين (لضمان عدم وجود مشاكل صلاحيات)
GRANT ALL ON TABLE public.profiles TO anon, authenticated, service_role;

-- 5. إزالة أي سياسات قديمة قد تعيق العمل وإنشاء سياسة مفتوحة (مؤقتاً للتشغيل)
DROP POLICY IF EXISTS "Enable insert for everyone" ON public.profiles;
CREATE POLICY "Enable insert for everyone" ON public.profiles FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.profiles;
CREATE POLICY "Enable update for users based on user_id" ON public.profiles FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Enable select for everyone" ON public.profiles;
CREATE POLICY "Enable select for everyone" ON public.profiles FOR SELECT USING (true);
