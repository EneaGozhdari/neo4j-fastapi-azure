"""Minimal FastAPI service exposing /health and /data.

Neo4j connection details are read exclusively from environment variables
(NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD) — nothing is hard-coded. The driver is
opened once at startup, reused for every request, and closed on shutdown.
"""

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from neo4j import GraphDatabase
from neo4j.exceptions import Neo4jError, ServiceUnavailable

# The single seeded node we expect to read back.
SEED_ID = "sample-1"
SEED_QUERY = """
MATCH (n:SeedData {id: $id})
RETURN n.id AS id, n.name AS name, n.type AS type
LIMIT 1
"""


def _require_env(name: str) -> str:
    """Return an env var's value or fail fast with a clear message."""
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Required environment variable '{name}' is not set")
    return value


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Read connection details from the environment (never hard-coded).
    uri = _require_env("NEO4J_URI")
    user = _require_env("NEO4J_USER")
    password = _require_env("NEO4J_PASSWORD")

    # Open the driver once and reuse it for the whole app lifetime.
    driver = GraphDatabase.driver(uri, auth=(user, password))
    app.state.driver = driver
    try:
        yield
    finally:
        driver.close()


app = FastAPI(title="Neo4j Sample API", version="1.0.0", lifespan=lifespan)


@app.get("/health")
def health():
    """Liveness/readiness signal. Must not touch the database."""
    return {"status": "ok"}


@app.get("/data")
def data():
    """Return the single seeded node from Neo4j."""
    driver = app.state.driver
    try:
        records, _, _ = driver.execute_query(
            SEED_QUERY, id=SEED_ID, database_="neo4j"
        )
    except (Neo4jError, ServiceUnavailable) as exc:
        raise HTTPException(status_code=503, detail=f"Neo4j unavailable: {exc}") from exc

    if not records:
        raise HTTPException(
            status_code=404,
            detail=(
                f"Seed node with id '{SEED_ID}' not found. "
                "Has the database been seeded?"
            ),
        )

    record = records[0]
    return {"id": record["id"], "name": record["name"], "type": record["type"]}
