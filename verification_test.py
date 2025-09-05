import os
import uuid
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

def main():
    """
    Main function to run the Vena Pictures Dashboard RLS verification tests.
    This script verifies that the Row-Level Security policies are correctly implemented.
    """
    print("🚀 Starting RLS Policy Verification Test Suite...")

    # --- Configuration ---
    url: str = os.environ.get("SUPABASE_URL")
    key: str = os.environ.get("SUPABASE_ANON_KEY")

    if not url or not key:
        print("❌ Error: SUPABASE_URL and SUPABASE_ANON_KEY must be set in the .env file.")
        return

    # --- Test Credentials ---
    main_user_email = "nopianhadi2@gmail.com"
    main_user_password = "Gedangburuk22.,"

    # NOTE: This test requires a SECOND user account to exist in the database
    # that is NOT the same as the main test user.
    attacker_email = "attacker@test.com"
    attacker_password = "password"

    print(f"🔑 Using Supabase URL: {url}")

    # --- Test Execution ---
    main_user_client = None
    attacker_client = None

    try:
        # Step 1: Authenticate as the main user
        print(f"\n--- Authenticating as main user ({main_user_email}) ---")
        main_user_client: Client = create_client(url, key)
        response = main_user_client.auth.sign_in_with_password({"email": main_user_email, "password": main_user_password})
        main_user_id = response.user.id
        main_user_client.postgrest.auth(response.session.access_token)
        print(f"✅ Main user authenticated successfully. User ID: {main_user_id}")

        # Step 2: Authenticate as the "attacker" user
        print(f"\n--- Authenticating as attacker user ({attacker_email}) ---")
        attacker_client: Client = create_client(url, key)
        try:
            response_attacker = attacker_client.auth.sign_in_with_password({"email": attacker_email, "password": attacker_password})
            attacker_id = response_attacker.user.id
            attacker_client.postgrest.auth(response_attacker.session.access_token)
            print(f"✅ Attacker user authenticated successfully. User ID: {attacker_id}")
        except Exception as auth_error:
            if "Invalid login credentials" in str(auth_error):
                print("\n❌ CRITICAL: Could not authenticate as the 'attacker' user.")
                print("   This test requires a second, pre-existing user account with the following credentials:")
                print(f"   - Email: {attacker_email}")
                print(f"   - Password: {attacker_password}")
                print("   Please create this user in your Supabase project and run the test again.")
                print("   The RLS verification test cannot proceed without this second user.")
                return # Exit the main function gracefully
            else:
                raise auth_error # Re-raise other unexpected auth errors

        # Step 3: Run the RLS verification tests
        print("\n--- Running RLS Verification Logic ---")
        run_rls_tests(main_user_client, main_user_id, attacker_client, attacker_id)

    except Exception as e:
        print(f"❌ An unexpected error occurred during the test setup: {e}")

    finally:
        print("\n✅ Test Suite Finished.")


def run_rls_tests(main_user_client: Client, main_user_id: str, attacker_client: Client, attacker_id: str):
    """
    Runs a series of tests to verify RLS policies.
    """
    test_client_name = f"Test Client for user {main_user_id[:8]}"
    attacker_client_name = f"Test Client for user {attacker_id[:8]}"

    try:
        # --- Main User Actions ---
        print(f"\n[1. MAIN USER] Creating a new client: '{test_client_name}'")
        # Note: The user_id is now automatically handled by the RLS policy's DEFAULT clause.
        # We don't need to pass it explicitly from the client, which is more secure.
        insert_response = main_user_client.table('clients').insert({"name": test_client_name, "status": "Prospek"}).execute()
        if not insert_response.data:
            raise Exception(f"Main user failed to insert a client. Error: {insert_response.error}")

        created_client_id = insert_response.data[0]['id']
        print(f"    ✅ SUCCESS: Main user created a client with ID: {created_client_id}")

        # --- Attacker Actions ---
        print(f"\n[2. ATTACKER] Attempting to read the main user's client (ID: {created_client_id})...")
        read_response = attacker_client.table('clients').select('*').eq('id', created_client_id).execute()

        if read_response.data:
            print(f"    🚨 FAILURE: Attacker was able to read the main user's client data.")
            print(f"       Data: {read_response.data}")
        else:
            print(f"    ✅ SUCCESS: Attacker could NOT read the main user's client, as expected.")

        print(f"\n[3. ATTACKER] Attempting to read ALL clients...")
        read_all_response = attacker_client.table('clients').select('*').execute()

        if any(client['user_id'] == main_user_id for client in read_all_response.data):
             print(f"    🚨 FAILURE: Attacker was able to see the main user's clients in a full table scan.")
        else:
            print(f"    ✅ SUCCESS: Attacker did NOT see the main user's clients in a full table scan.")


        print(f"\n[4. ATTACKER] Attempting to create their OWN client: '{attacker_client_name}'")
        attacker_insert_res = attacker_client.table('clients').insert({"name": attacker_client_name, "status": "Prospek"}).execute()
        if not attacker_insert_res.data:
             raise Exception(f"Attacker user failed to insert their own client. Error: {attacker_insert_res.error}")

        print(f"    ✅ SUCCESS: Attacker created their own client.")

    except Exception as e:
        print(f"❌ An error occurred during RLS tests: {e}")

    finally:
        # --- Cleanup ---
        print("\n--- Cleaning up test data ---")
        try:
            main_user_client.table('clients').delete().eq('name', test_client_name).execute()
            print(f"    - Deleted main user's test client.")
            attacker_client.table('clients').delete().eq('name', attacker_client_name).execute()
            print(f"    - Deleted attacker's test client.")
        except Exception as e:
            print(f"    ⚠️  Cleanup failed. You may need to manually remove test data. Error: {e}")


if __name__ == "__main__":
    main()
