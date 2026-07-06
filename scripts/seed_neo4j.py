"""Idempotently seed a single SeedData node into Neo4j.

Reads the same environment variables as the API (NEO4J_URI, NEO4J_USER,
NEO4J_PASSWORD). Uses MERGE so re-running never creates duplicates. Retries for
a short while so it is safe to run as soon as Neo4j starts accepting requests.
"""

import os
import sys
import time

from neo4j import GraphDatabase
from neo4j.exceptions import ServiceUnavailable

SEED = {"id": "sample-1", "name": "Example Node", "type": "SeedData"}

MERGE_QUERY = """
MERGE (n:SeedData {id: $id})
SET n.name = $name, n.type = $type
RETURN n.id AS id, n.name AS name, n.type AS type
"""

MAX_ATTEMPTS = 30
RETRY_SECONDS = 2


def _require_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        sys.exit(f"ERROR: required environment variable '{name}' is not set")
    return value


def main() -> None:
    uri = _require_env("NEO4J_URI")
    user = _require_env("NEO4J_USER")
    password = _require_env("NEO4J_PASSWORD")

    last_err = None
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            with GraphDatabase.driver(uri, auth=(user, password)) as driver:
                records, _, _ = driver.execute_query(
                    MERGE_QUERY, database_="neo4j", **SEED
                )
                node = records[0]
                print(
                    "Seeded node: "
                    f"id={node['id']} name={node['name']} type={node['type']}"
                )
                return
        except ServiceUnavailable as exc:
            last_err = exc
            print(f"Neo4j not ready (attempt {attempt}/{MAX_ATTEMPTS}): {exc}")
            time.sleep(RETRY_SECONDS)

    sys.exit(f"ERROR: could not connect to Neo4j after retries: {last_err}")


if __name__ == "__main__":
    main()
