import uuid
from neo4j import GraphDatabase, exceptions

# Connect to the Fabric router
URI = "bolt://localhost:7687"
AUTH = ("neo4j", "password")
DATABASE = "fabric"


class AtomicityTest:
    """
    This class encapsulates the logic for the atomicity test.
    It checks if a cross-shard transaction is atomic (all or nothing).
    """

    def __init__(self, uri, auth, database):
        """Initializes the test by connecting to the database."""
        self.driver = GraphDatabase.driver(uri, auth=auth)
        self.database = database
        self.person_id = None
        # Generate a unique ID for the test post to avoid conflicts between runs.
        self.post_id = str(uuid.uuid4())

    def close(self):
        """Closes the database connection."""
        self.driver.close()

    def _find_person(self):
        """
        Setup Step: Finds a single Person node to act as the creator of a post.
        This person exists on the 'persons' shard.
        """
        print("Step 1: Finding a Person node to act as the creator...")
        with self.driver.session(database=self.database) as session:
            result = session.run("USE fabric.persons MATCH (p:Person) RETURN p LIMIT 1")
            record = result.single()
            if not record:
                raise Exception("Could not find any Person nodes. Please ensure the LDBC data is loaded correctly.")
            person_node = record["p"]
            self.person_id = person_node["id"]
            print(f"-> Found Person with ID: {self.person_id} (on 'persons' shard)")
            return True

    def run_test_and_force_rollback(self):
        """
        Test Step: Runs the main cross-shard transaction and forces a failure.
        1. Starts a transaction.
        2. Creates a :Post node (on 'forums' shard).
        3. Creates a :HAS_CREATOR relationship from our :Person node.
        4. Forces a rollback by raising an exception before the transaction commits.
        """
        print("\nStep 2: Running the cross-shard transaction test...")
        try:
            with self.driver.session(database=self.database) as session:
                # The 'with' statement for a transaction ensures that if the block
                # exits with an exception, the transaction is automatically rolled back.
                with session.begin_transaction() as tx:
                    print("-> Transaction started.")
                    print(f"-> Attempting to CREATE a Post (ID: {self.post_id}) on the 'forums' shard.")
                    
                    query = """
                    // Find the Person node on the 'persons' shard
                    MATCH (p:Person {id: $person_id})
                    // Create the Post node on the 'forums' shard
                    CREATE (post:Post {id: $post_id, creationDate: datetime(), content: 'This is a test post for atomicity.'})
                    // Create the cross-shard relationship
                    CREATE (p)-[:HAS_CREATOR]->(post)
                    RETURN id(post)
                    """
                    tx.run(query, person_id=self.person_id, post_id=self.post_id)
                    
                    print("-> Create query executed within the transaction block.")
                    
                    # This is the key part of the test: we force a failure before the 'with' block can complete and commit.
                    raise Exception("ROLLBACK_FORCED: Intentionally forcing a rollback to test atomicity.")

        except Exception as e:
            # We expect to catch our own forced exception. This is part of the test.
            if "ROLLBACK_FORCED" in str(e):
                print("-> Successfully caught the forced exception.")
                print("-> The neo4j driver should have automatically rolled back the transaction.")
            else:
                # If a different exception occurs, something else is wrong.
                print(f"An unexpected error occurred during the transaction: {e}")
                raise # Re-raise the exception because it's not the one we planned for.

    def verify_rollback(self):
        """
        Verification Step: Checks that the transaction was correctly rolled back.
        """
        print("\nStep 3: Verifying that the transaction was rolled back...")
        with self.driver.session(database=self.database) as session:
            # This query will be routed to the 'forums' shard by Fabric.
            query = "MATCH (p:Post {id: $post_id}) RETURN p"
            result = session.run(query, post_id=self.post_id)
            record = result.single()
            
            if record:
                print("--- ❌ TEST FAILED ---")
                print(f"A Post with ID {self.post_id} was found in the database.")
                print("This indicates the transaction was NOT atomic, as data was partially committed.")
            else:
                print("--- ✅ TEST PASSED ---")
                print(f"No Post with ID {self.post_id} was found.")
                print("This confirms the cross-shard transaction was correctly rolled back (atomicity holds).")


def main():
    """Main function to run the atomicity test."""
    # Before running, make sure you have the neo4j driver installed:
    # pip install neo4j
    
    print("--- Crawl: Atomicity Check for Cross-Shard Transactions ---")
    
    test = None
    try:
        test = AtomicityTest(URI, AUTH, DATABASE)
        if test._find_person():
            test.run_test_and_force_rollback()
            test.verify_rollback()
    except exceptions.AuthError:
        print(f"\n[Error] Authentication failed. Please check the credentials in the script.")
    except exceptions.ServiceUnavailable:
        print(f"\n[Error] Could not connect to the database at {URI}.")
        print("Please ensure your Neo4j Fabric container is running and accessible.")
    except Exception as e:
        print(f"\nAn unexpected error occurred: {e}")
    finally:
        if test:
            test.close()
        print("\n--- Test complete. ---")


if __name__ == "__main__":
    main() 