-- ============================================================
-- إصلاح قاعدة البيانات - إنشاء جدول profiles والدوال المفقودة
-- ============================================================

-- 1. إنشاء جدول profiles إذا لم يكن موجوداً
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id),
    phone text UNIQUE NOT NULL,
    name text,
    address text,
    user_id_text text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 2. تمكين RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. إنشاء السياسات (Policies)
-- حذف السياسات القديمة لتجنب التكرار
DROP POLICY IF EXISTS "service_role_all" ON public.profiles;
DROP POLICY IF EXISTS "anon_select" ON public.profiles;
DROP POLICY IF EXISTS "anon_insert" ON public.profiles;
DROP POLICY IF EXISTS "anon_update" ON public.profiles;
DROP POLICY IF EXISTS "authenticated_all" ON public.profiles;

-- سياسة الوصول الكامل لـ Service Role
CREATE POLICY "service_role_all" ON public.profiles
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- سياسة القراءة للجميع (مؤقتاً لحل المشاكل)
CREATE POLICY "public_select" ON public.profiles
    FOR SELECT
    USING (true);

-- سياسة الإضافة للجميع (للتسجيل)
CREATE POLICY "public_insert" ON public.profiles
    FOR INSERT
    WITH CHECK (true);

-- سياسة التحديث للجميع
CREATE POLICY "public_update" ON public.profiles
    FOR UPDATE
    USING (true);

-- 4. إنشاء دالة rpc_create_profile (المستخدمة في التطبيق)
CREATE OR REPLACE FUNCTION public.rpc_create_profile(
    p_name text,
    p_phone text,
    p_address text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_profile public.profiles;
BEGIN
    -- محاولة الإدخال أو التحديث
    INSERT INTO public.profiles (name, phone, address, user_id_text)
    VALUES (p_name, p_phone, p_address, p_phone)
    ON CONFLICT (phone) DO UPDATE
    SET
        name = EXCLUDED.name,
        address = EXCLUDED.address,
        updated_at = now()
    RETURNING * INTO v_profile;

    RETURN row_to_json(v_profile);
END;
$$;

-- 5. إنشاء دالة exec_sql (للصيانة عن بعد مستقبلاً)
CREATE OR REPLACE FUNCTION public.exec_sql(sql text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    EXECUTE sql;
    RETURN 'Success';
END;
$$;

-- 6. منح الصلاحيات
GRANT ALL ON public.profiles TO anon;
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;

GRANT EXECUTE ON FUNCTION public.rpc_create_profile TO anon;
GRANT EXECUTE ON FUNCTION public.rpc_create_profile TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_create_profile TO service_role;

GRANT EXECUTE ON FUNCTION public.exec_sql TO service_role;

-- 7. تحديث جدول auth.users (اختياري - لتنظيف المستخدمين القدامى إذا لزم الأمر)
-- لا يمكننا حذف المستخدمين من هنا بسهولة، ولكن يمكننا التأكد من أن الجدول جاهز.

SELECT 'Database Fixed Successfully' as result;
