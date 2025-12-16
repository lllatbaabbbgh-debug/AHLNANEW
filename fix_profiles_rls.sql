-- إصلاح سياسات RLS لجدول profiles للسماح بالعمليات بشكل صحيح
-- حذف السياسات القديمة
DROP POLICY IF EXISTS "auth_read_own_profile" ON public.profiles;
DROP POLICY IF EXISTS "auth_upsert_own_profile" ON public.profiles;
DROP POLICY IF EXISTS "auth_update_own_profile" ON public.profiles;
DROP POLICY IF EXISTS "anon_upsert_profiles" ON public.profiles;
DROP POLICY IF EXISTS "anon_update_profiles" ON public.profiles;
DROP POLICY IF EXISTS "anon_select_profiles" ON public.profiles;

-- إنشاء سياسات جديدة أكثر مرونة
-- السماح للمستخدمين المعتمدين بقراءة ملفاتهم الشخصية
CREATE POLICY "authenticated_read_profiles" ON public.profiles
    FOR SELECT TO authenticated USING (true);

-- السماح للمستخدمين المعتمدين بإدراج ملفاتهم الشخصية
CREATE POLICY "authenticated_insert_profiles" ON public.profiles
    FOR INSERT TO authenticated WITH CHECK (true);

-- السماح للمستخدمين المعتمدين بتحديث ملفاتهم الشخصية
CREATE POLICY "authenticated_update_profiles" ON public.profiles
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- السماح للمستخدمين المجهولين بإدراج ملفاتهم الشخصية
CREATE POLICY "anon_insert_profiles" ON public.profiles
    FOR INSERT TO anon WITH CHECK (true);

-- السماح للمستخدمين المجهولين بتحديث ملفاتهم الشخصية باستخدام رقم الهاتف
CREATE POLICY "anon_update_profiles_by_phone" ON public.profiles
    FOR UPDATE TO anon USING (phone = current_setting('app.current_phone', true)::text) WITH CHECK (phone = current_setting('app.current_phone', true)::text);

-- السماح للمستخدمين المجهولين بقراءة الملفات الشخصية
CREATE POLICY "anon_select_profiles" ON public.profiles
    FOR SELECT TO anon USING (true);

-- إنشاء دالة لتمكين Service Role من الوصول الكامل
CREATE OR REPLACE FUNCTION service_role_access_profiles()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user = 'supabase_admin' OR current_user = 'authenticator';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- سياسة خاصة لـ Service Role للوصول الكامل
CREATE POLICY "service_role_all_profiles" ON public.profiles
    FOR ALL USING (service_role_access_profiles());

-- تمكين RLS على جدول profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;