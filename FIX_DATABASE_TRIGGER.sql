-- هذا الملف يحتوي على الحل الجذري لمشكلة "تعذر تحديث قاعدة البيانات"
-- المشكلة سببها وجود "Trigger" قديم يحاول الوصول لعمود "user" الذي تم حذفه.
-- قم بنسخ هذا الكود وتشغيله في لوحة تحكم Supabase (SQL Editor).

-- 1. حذف الدالة القديمة المسببة للمشكلة
DROP TRIGGER IF EXISTS on_auth_user_created ON public.users; -- مثال، قد يكون الاسم مختلفاً
DROP FUNCTION IF EXISTS validate_profile_data() CASCADE;

-- 2. إعادة إنشاء الدالة بشكل صحيح (بدون الإشارة لعمود user)
CREATE OR REPLACE FUNCTION validate_profile_data()
RETURNS TRIGGER AS $$
BEGIN
    -- التحقق من أن رقم الهاتف ليس فارغًا
    IF NEW.phone IS NULL OR TRIM(NEW.phone) = '' THEN
        RAISE EXCEPTION 'رقم الهاتف مطلوب';
    END IF;
    
    -- التعامل مع user_id_text بدلاً من user القديم
    IF NEW.user_id_text IS NULL OR TRIM(NEW.user_id_text) = '' THEN
        NEW.user_id_text := NEW.phone;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. إعادة ربط الـ Trigger (اختياري، إذا كنت تحتاجه)
-- CREATE TRIGGER check_profile_data
-- BEFORE INSERT OR UPDATE ON public.profiles
-- FOR EACH ROW EXECUTE FUNCTION validate_profile_data();

-- 4. إصلاح المشكلة فوراً عن طريق حذف الـ Trigger القديم فقط (الأكثر أماناً الآن)
DROP TRIGGER IF EXISTS check_profile_data ON public.profiles;
