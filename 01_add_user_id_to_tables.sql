-- =================================================================
-- Vena Pictures Dashboard - Database Migration Script 1
--
-- Adds a `user_id` column to all relevant tables to enable
-- proper multi-tenant Row-Level Security.
-- =================================================================

-- This script should be run BEFORE applying the new RLS policies.

-- #################################################################
-- ### WARNING: FOR DEVELOPMENT/SINGLE-TENANT USE ONLY           ###
-- #################################################################
-- This script assumes that all existing data in the database belongs
-- to a single user (the first admin found).
--
-- DO NOT RUN THIS ON A PRODUCTION MULTI-TENANT DATABASE
-- without first modifying the backfilling logic to correctly
-- associate each record with its true owner.
-- #################################################################

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
        ALTER TABLE public.clients ADD CONSTRAINT fk_clients_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to clients';
    END IF;

    -- Table: packages
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='packages' AND column_name='user_id') THEN
        ALTER TABLE public.packages ADD COLUMN user_id UUID;
        UPDATE public.packages SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.packages ADD CONSTRAINT fk_packages_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to packages';
    END IF;

    -- Table: add_ons
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='add_ons' AND column_name='user_id') THEN
        ALTER TABLE public.add_ons ADD COLUMN user_id UUID;
        UPDATE public.add_ons SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.add_ons ADD CONSTRAINT fk_add_ons_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to add_ons';
    END IF;

    -- Table: team_members
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='team_members' AND column_name='user_id') THEN
        ALTER TABLE public.team_members ADD COLUMN user_id UUID;
        UPDATE public.team_members SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.team_members ADD CONSTRAINT fk_team_members_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to team_members';
    END IF;

    -- Table: projects
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='user_id') THEN
        ALTER TABLE public.projects ADD COLUMN user_id UUID;
        UPDATE public.projects SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.projects ADD CONSTRAINT fk_projects_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to projects';
    END IF;

    -- Table: cards
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='cards' AND column_name='user_id') THEN
        ALTER TABLE public.cards ADD COLUMN user_id UUID;
        UPDATE public.cards SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.cards ADD CONSTRAINT fk_cards_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to cards';
    END IF;

    -- Table: financial_pockets
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='financial_pockets' AND column_name='user_id') THEN
        ALTER TABLE public.financial_pockets ADD COLUMN user_id UUID;
        UPDATE public.financial_pockets SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.financial_pockets ADD CONSTRAINT fk_financial_pockets_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to financial_pockets';
    END IF;

    -- Table: transactions
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='transactions' AND column_name='user_id') THEN
        ALTER TABLE public.transactions ADD COLUMN user_id UUID;
        UPDATE public.transactions SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.transactions ADD CONSTRAINT fk_transactions_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to transactions';
    END IF;

    -- Table: leads
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='leads' AND column_name='user_id') THEN
        ALTER TABLE public.leads ADD COLUMN user_id UUID;
        UPDATE public.leads SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.leads ADD CONSTRAINT fk_leads_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to leads';
    END IF;

    -- Table: team_project_payments
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='team_project_payments' AND column_name='user_id') THEN
        ALTER TABLE public.team_project_payments ADD COLUMN user_id UUID;
        UPDATE public.team_project_payments SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.team_project_payments ADD CONSTRAINT fk_team_project_payments_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to team_project_payments';
    END IF;

    -- Table: assets
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='assets' AND column_name='user_id') THEN
        ALTER TABLE public.assets ADD COLUMN user_id UUID;
        UPDATE public.assets SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.assets ADD CONSTRAINT fk_assets_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to assets';
    END IF;

    -- Table: contracts
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='contracts' AND column_name='user_id') THEN
        ALTER TABLE public.contracts ADD COLUMN user_id UUID;
        UPDATE public.contracts SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.contracts ADD CONSTRAINT fk_contracts_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to contracts';
    END IF;

    -- Table: client_feedback
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='client_feedback' AND column_name='user_id') THEN
        ALTER TABLE public.client_feedback ADD COLUMN user_id UUID;
        UPDATE public.client_feedback SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.client_feedback ADD CONSTRAINT fk_client_feedback_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to client_feedback';
    END IF;

    -- Table: notifications
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='notifications' AND column_name='user_id') THEN
        ALTER TABLE public.notifications ADD COLUMN user_id UUID;
        UPDATE public.notifications SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.notifications ADD CONSTRAINT fk_notifications_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to notifications';
    END IF;

    -- Table: social_media_posts
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='social_media_posts' AND column_name='user_id') THEN
        ALTER TABLE public.social_media_posts ADD COLUMN user_id UUID;
        UPDATE public.social_media_posts SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.social_media_posts ADD CONSTRAINT fk_social_media_posts_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to social_media_posts';
    END IF;

    -- Table: promo_codes
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='promo_codes' AND column_name='user_id') THEN
        ALTER TABLE public.promo_codes ADD COLUMN user_id UUID;
        UPDATE public.promo_codes SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.promo_codes ADD CONSTRAINT fk_promo_codes_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to promo_codes';
    END IF;

    -- Table: sops
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='sops' AND column_name='user_id') THEN
        ALTER TABLE public.sops ADD COLUMN user_id UUID;
        UPDATE public.sops SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.sops ADD CONSTRAINT fk_sops_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to sops';
    END IF;

    -- Table: team_payment_records
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='team_payment_records' AND column_name='user_id') THEN
        ALTER TABLE public.team_payment_records ADD COLUMN user_id UUID;
        UPDATE public.team_payment_records SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.team_payment_records ADD CONSTRAINT fk_team_payment_records_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to team_payment_records';
    END IF;

    -- Table: reward_ledger_entries
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='reward_ledger_entries' AND column_name='user_id') THEN
        ALTER TABLE public.reward_ledger_entries ADD COLUMN user_id UUID;
        UPDATE public.reward_ledger_entries SET user_id = admin_user_id_to_backfill WHERE user_id IS NULL;
        ALTER TABLE public.reward_ledger_entries ADD CONSTRAINT fk_reward_ledger_entries_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_id to reward_ledger_entries';
    END IF;

END $$;

RAISE NOTICE 'Finished adding user_id columns to all tables.';
