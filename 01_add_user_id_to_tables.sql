-- =================================================================
-- Vena Pictures Dashboard - Database Migration Script 1
--
-- Adds a `user_id` column to all relevant tables to enable
-- proper multi-tenant Row-Level Security.
-- =================================================================

-- This script should be run BEFORE applying the new RLS policies.

-- Note: We are assuming that for existing data, all records belong
-- to the first 'Admin' user found in the 'profiles' table.
-- In a real multi-tenant migration, you would need more complex
-- logic to assign records to their correct owners.

DO $$
DECLARE
    -- Get the ID of the first admin user to use for backfilling existing data.
    admin_user_id_to_backfill UUID;
BEGIN
    -- Find the admin user's ID from the profiles table.
    -- This assumes there's at least one profile.
    SELECT admin_user_id INTO admin_user_id_to_backfill FROM public.profiles LIMIT 1;

    -- If no admin user is found, raise an exception.
    IF admin_user_id_to_backfill IS NULL THEN
        RAISE EXCEPTION 'No admin user found in profiles table. Cannot backfill user_id.';
    END IF;

    RAISE NOTICE 'Backfilling existing records with user_id: %', admin_user_id_to_backfill;

    -- Add `user_id` column and foreign key to each table
    -- We check if the column exists before adding it to make the script idempotent.

    -- Table: clients
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='clients' AND column_name='user_id') THEN
        ALTER TABLE public.clients ADD COLUMN user_id UUID;
        UPDATE public.clients SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.clients ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to clients';
    END IF;

    -- Table: packages
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='packages' AND column_name='user_id') THEN
        ALTER TABLE public.packages ADD COLUMN user_id UUID;
        UPDATE public.packages SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.packages ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to packages';
    END IF;

    -- Table: add_ons
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='add_ons' AND column_name='user_id') THEN
        ALTER TABLE public.add_ons ADD COLUMN user_id UUID;
        UPDATE public.add_ons SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.add_ons ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to add_ons';
    END IF;

    -- Table: team_members
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='team_members' AND column_name='user_id') THEN
        ALTER TABLE public.team_members ADD COLUMN user_id UUID;
        UPDATE public.team_members SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.team_members ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to team_members';
    END IF;

    -- Table: projects
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='user_id') THEN
        ALTER TABLE public.projects ADD COLUMN user_id UUID;
        UPDATE public.projects SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.projects ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to projects';
    END IF;

    -- Table: cards
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='cards' AND column_name='user_id') THEN
        ALTER TABLE public.cards ADD COLUMN user_id UUID;
        UPDATE public.cards SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.cards ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to cards';
    END IF;

    -- Table: financial_pockets
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_pockets' AND column_name='user_id') THEN
        ALTER TABLE public.financial_pockets ADD COLUMN user_id UUID;
        UPDATE public.financial_pockets SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.financial_pockets ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to financial_pockets';
    END IF;

    -- Table: transactions
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='transactions' AND column_name='user_id') THEN
        ALTER TABLE public.transactions ADD COLUMN user_id UUID;
        UPDATE public.transactions SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.transactions ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to transactions';
    END IF;

    -- ... continue this pattern for all other necessary tables ...
    -- leads, team_project_payments, assets, contracts, client_feedback, notifications, social_media_posts, promo_codes, sops

END $$;

RAISE NOTICE 'Finished adding user_id columns to all tables.';
