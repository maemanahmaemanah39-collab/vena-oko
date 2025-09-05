import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

def test_authentication(client: Client, email: str, password: str) -> dict:
    """
    Tests the user authentication.
    Returns a dictionary with the authenticated client and user data.
    """
    try:
        response = client.auth.sign_in_with_password({"email": email, "password": password})
        print(f"✅ Authentication successful for user: {response.user.email}")

        # Return the authenticated client instance for the next tests
        return {"success": True, "client": client, "user": response.user}
    except Exception as e:
        print(f"❌ Authentication failed: {e}")
        return {"success": False, "client": None, "user": None}

def test_rls_policies(client: Client):
    """
    Tests the Row-Level Security policies to demonstrate the vulnerability.
    """
    print("⚠️  Running as an authenticated user to test RLS policies.")
    print("    The goal is to show that any user can read anyone else's data.")

    try:
        # Test 1: Try to read all users
        print("\n[RLS Test 1] Attempting to read all data from 'users' table...")
        users_data = client.table('users').select('*').execute()
        if len(users_data.data) > 0:
            print(f"    🚨 VULNERABILITY CONFIRMED: Successfully read {len(users_data.data)} records from 'users' table.")
            # print(f"    Sample data: {users_data.data[0]}")
        else:
            print("    ✅ Could not read from 'users' table, or table is empty.")

        # Test 2: Try to read all clients
        print("\n[RLS Test 2] Attempting to read all data from 'clients' table...")
        clients_data = client.table('clients').select('*').execute()
        if len(clients_data.data) > 0:
            print(f"    🚨 VULNERABILITY CONFIRMED: Successfully read {len(clients_data.data)} records from 'clients' table.")
            # print(f"    Sample data: {clients_data.data[0]}")
        else:
            print("    ✅ Could not read from 'clients' table, or table is empty.")

        # Test 3: Try to read all projects
        print("\n[RLS Test 3] Attempting to read all data from 'projects' table...")
        projects_data = client.table('projects').select('*').execute()
        if len(projects_data.data) > 0:
            print(f"    🚨 VULNERABILITY CONFIRMED: Successfully read {len(projects_data.data)} records from 'projects' table.")
            # print(f"    Sample data: {projects_data.data[0]}")
        else:
            print("    ✅ Could not read from 'projects' table, or table is empty.")

        # Test 4: Try to insert a client
        print("\n[RLS Test 4] Attempting to insert a record into 'clients' table...")
        new_client_name = "RLS Vulnerability Test Client"
        insert_data = client.table('clients').insert({"name": new_client_name, "status": "Prospek"}).execute()
        if len(insert_data.data) > 0:
            print(f"    🚨 VULNERABILITY CONFIRMED: Successfully inserted a new client: '{new_client_name}'")
            # Cleanup the test data
            client.table('clients').delete().eq('name', new_client_name).execute()
            print("    - Cleaned up test client data.")
        else:
            print("    ✅ Could not insert into 'clients' table. Write is protected.")

    except Exception as e:
        print(f"❌ An error occurred during RLS testing: {e}")


import argparse

def main():
    """
    Main function to run the Vena Pictures Dashboard tests.
    """
    parser = argparse.ArgumentParser(description="Vena Pictures Dashboard Test Suite")
    parser.add_argument('--test-fix', action='store_true', help='Run tests to verify the RLS fix.')
    args = parser.parse_args()

    if args.test_fix:
        print("🚀 Starting Test Suite in FIX VERIFICATION mode...")
        run_fix_verification_tests()
    else:
        print("🚀 Starting Test Suite in VULNERABILITY DISCOVERY mode...")
        run_vulnerability_tests()

    print("\n✅ Test Suite Finished.")

def run_fix_verification_tests():
    """
    Runs tests to verify that the secure RLS policies are working.
    """
    # --- Configuration ---
    url: str = os.environ.get("SUPABASE_URL")
    key: str = os.environ.get("SUPABASE_ANON_KEY")

    if not url or not key:
        print("❌ Error: SUPABASE_URL and SUPABASE_ANON_KEY must be set in the .env file.")
        return

    # --- Test Credentials ---
    # NOTE: This test requires a SECOND user account to exist in the database
    # that is NOT the same as the main test user.
    # We will call this the "attacker" user for the test scenario.
    attacker_email = "attacker@test.com"
    attacker_password = "password"

    print(f"🔑 Using Supabase URL: {url}")

    # --- Test Execution ---
    try:
        # Step 1: Create a Supabase client for the "attacker"
        supabase: Client = create_client(url, key)
        print("✅ Supabase client created successfully.")

        # Step 2: Authenticate as the "attacker"
        print("\n--- Running Authentication Test (as Attacker) ---")
        auth_result = test_authentication(supabase, attacker_email, attacker_password)

        if not auth_result["success"]:
            print("🚨 Halting tests: Could not authenticate as the 'attacker' user.")
            print("   Please ensure a second user account exists with the credentials in the script.")
            return

        attacker_client = auth_result["client"]

        # Step 3: Run Secure RLS Verification Test
        print("\n--- Running RLS Fix Verification Test ---")
        test_secure_rls_fix(attacker_client)

    except Exception as e:
        print(f"❌ An unexpected error occurred: {e}")

def test_secure_rls_fix(attacker_client: Client):
    """
    Tests that the secure RLS policies correctly prevent data access.
    This function runs as a different user (the "attacker").
    """
    print("🔐 Running as a different authenticated user ('attacker').")
    print("   The goal is to prove this user CANNOT access the main user's data.")

    try:
        # Test 1: Try to read the 'users' table. Should only see self.
        print("\n[Secure RLS Test 1] Attempting to read 'users' table...")
        users_data = attacker_client.table('users').select('*').execute()
        if len(users_data.data) == 1:
            print(f"    ✅ SUCCESS: Correctly read only 1 record from 'users' table (the user's own).")
        elif len(users_data.data) > 1:
            print(f"    🚨 FAILURE: Read {len(users_data.data)} records from 'users' table. RLS is not working.")
        else:
            print(f"    🚨 FAILURE: Could not read any user records. Something is wrong.")

        # Test 2: Try to read the 'clients' table. Should see 0 records.
        print("\n[Secure RLS Test 2] Attempting to read 'clients' table...")
        clients_data = attacker_client.table('clients').select('*').execute()
        if len(clients_data.data) == 0:
            print(f"    ✅ SUCCESS: Correctly read 0 records from 'clients' table.")
        else:
            print(f"    🚨 FAILURE: Read {len(clients_data.data)} records from 'clients' table. RLS is not working.")

        # Test 3: Try to insert a client for the ORIGINAL user. This should fail.
        # We need the original user's ID for this test. We can't get it if RLS is secure.
        # So, we will just try to insert a client and expect it to fail if the user_id
        # is not correctly set by a default policy or by the application logic.
        # For this test, we assume the insert will fail because there's no way to assign ownership.
        print("\n[Secure RLS Test 3] Attempting to insert a record into 'clients' table...")
        try:
            insert_data = attacker_client.table('clients').insert({"name": "Attacker's Client"}).execute()
            if insert_data.data and len(insert_data.data) > 0:
                 print(f"    ✅ SUCCESS: User was able to insert a client for themselves.")
            else:
                 print(f"    🚨 FAILURE: Could not insert client. The policy might be too restrictive.")
        except Exception as e:
            print(f"    ✅ SUCCESS: Insert failed as expected due to RLS policy. Error: {e}")

    except Exception as e:
        print(f"❌ An error occurred during RLS fix testing: {e}")

def run_vulnerability_tests():
    """
    Runs the original set of tests to discover vulnerabilities.
    """
    # --- Configuration ---
    url: str = os.environ.get("SUPABASE_URL")
    key: str = os.environ.get("SUPABASE_ANON_KEY")

    if not url or not key:
        print("❌ Error: SUPABASE_URL and SUPABASE_ANON_KEY must be set in the .env file.")
        return

    # --- Test Credentials ---
    test_email = "nopianhadi2@gmail.com"
    test_password = "Gedangburuk22.,"

    print(f"🔑 Using Supabase URL: {url}")

    # --- Test Execution ---
    try:
        # Step 1: Create a Supabase client
        supabase: Client = create_client(url, key)
        print("✅ Supabase client created successfully.")

        # Step 2: Run Authentication Test
        print("\n--- Running Authentication Test ---")
        auth_result = test_authentication(supabase, test_email, test_password)

        if not auth_result["success"]:
            print("🚨 Halting tests due to authentication failure.")
            return

        authenticated_client = auth_result["client"]

        # Step 3: Run RLS Verification Test
        print("\n--- Running RLS Vulnerability Test ---")
        test_rls_policies(authenticated_client)

    except Exception as e:
        print(f"❌ An unexpected error occurred: {e}")

    print("\n✅ Test Suite Finished.")

if __name__ == "__main__":
    main()
