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
        """
        print("\nStep 2: Running the cross-shard transaction test...")
        try:
            with self.driver.session(database=self.database) as session:
                with session.begin_transaction() as tx:
                    print("-> Transaction started.")
                    print(f"-> Attempting to CREATE a Post (ID: {self.post_id}) on the 'forums' shard.")
                    
                    create_post_query = """
                    USE fabric.forums
                    CREATE (post:Post {
                        id: $post_id, 
                        creationDate: datetime(), 
                        content: 'Test post for atomicity',
                        creatorId: $person_id
                    })
                    RETURN post.id as created_post_id
                    """

                    result = tx.run(create_post_query, post_id=self.post_id, person_id=self.person_id)
                    created_post = result.single()
                    print(f"-> Post created with ID: {created_post['created_post_id']}")
                    
                    # Test 2: Update Person on persons shard (to simulate cross-shard operation)
                    print(f"-> Updating Person (ID: {self.person_id}) on 'persons' shard...")
                    update_person_query = """
                    USE fabric.persons
                    MATCH (p:Person {id: $person_id})
                    SET p.lastPostId = $post_id
                    RETURN p.id as updated_person_id
                    """
                    result = tx.run(update_person_query, person_id=self.person_id, post_id=self.post_id)
                    updated_person = result.single()
                    print(f"-> Person updated with ID: {updated_person['updated_person_id']}")
                    
                    print("-> Both operations completed within transaction block.")
                    
                    # Force rollback to test atomicity
                    raise Exception("ROLLBACK_FORCED: Intentionally forcing a rollback to test atomicity.")

        except Exception as e:
            # We expect to catch our own forced exception. This is part of the test.
            if "ROLLBACK_FORCED" in str(e):
                print("-> Successfully caught the forced exception.")
                print("-> The neo4j driver should have automatically rolled back the transaction.")
            else:
                print(f"An unexpected error occurred during the transaction: {e}")

    def verify_rollback(self):
        """
        Verification Step: Checks that the transaction was correctly rolled back.
        """
        print("\nStep 3: Verifying that the transaction was rolled back...")
        with self.driver.session(database=self.database) as session:
            # This query will be routed to the 'forums' shard by Fabric.
            post_query = "USE fabric.forums MATCH (p:Post {id: $post_id}) RETURN p"
            result = session.run(post_query, post_id=self.post_id)
            post_record = result.single()

            person_query = "USE fabric.persons MATCH (p:Person {id: $person_id}) RETURN p.lastPostId as lastPostId"
            result = session.run(person_query, person_id=self.person_id)
            person_record = result.single()

            post_exists = post_record is not None
            person_updated = person_record and person_record["lastPostId"] == self.post_id
            
            if not post_exists and not person_updated:
                print("TEST PASSED!")
            elif post_exists and person_updated:
                print("TEST FAILED!")
            else:
                print("Only one operation was committed.")


def main():
    """Main function to run the atomicity test."""
    
    print("--- Atomicity Check for Cross-Shard Transactions ---")
    
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