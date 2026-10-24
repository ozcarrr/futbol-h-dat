-- =====================================================================
-- Esquema de Base de Datos y Políticas RLS para FutboLE (Certamen 2)
-- Tabla: public.custom_challenges
-- =====================================================================

-- 1. Crear extensión para UUIDs si no existe
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Crear tabla de desafíos personalizados vinculada a auth.users
CREATE TABLE IF NOT EXISTS public.custom_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    target_name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'trivia',
    clue_1 TEXT NOT NULL,
    clue_2 TEXT NOT NULL,
    clue_3 TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3. Habilitar Seguridad a Nivel de Fila (Row Level Security - RLS)
ALTER TABLE public.custom_challenges ENABLE ROW LEVEL SECURITY;

-- 4. Política RLS: SELECT (Los usuarios solo pueden consultar sus propios desafíos)
CREATE POLICY "Users can view their own challenges"
ON public.custom_challenges
FOR SELECT
USING (auth.uid() = user_id);

-- 5. Política RLS: INSERT (Los usuarios solo pueden insertar desafíos con su propio user_id)
CREATE POLICY "Users can insert their own challenges"
ON public.custom_challenges
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- 6. Política RLS: UPDATE (Los usuarios solo pueden editar sus propios desafíos)
CREATE POLICY "Users can update their own challenges"
ON public.custom_challenges
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 7. Política RLS: DELETE (Los usuarios solo pueden eliminar sus propios desafíos)
CREATE POLICY "Users can delete their own challenges"
ON public.custom_challenges
FOR DELETE
USING (auth.uid() = user_id);

-- 8. Índice para optimizar consultas por user_id
CREATE INDEX IF NOT EXISTS idx_custom_challenges_user_id
ON public.custom_challenges(user_id);
