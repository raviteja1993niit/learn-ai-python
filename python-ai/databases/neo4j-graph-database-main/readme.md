# 🕸️ Neo4j — Graph Database for Knowledge Graphs & GraphRAG

## What is Neo4j?
Neo4j is a native graph database that stores data as nodes, relationships, and properties, queried with the Cypher language. It excels at connected data problems like recommendation engines, fraud detection, and knowledge graphs. In AI, it powers GraphRAG by representing entity relationships that vector search alone cannot capture.

## Why Learn It?
- Model and query richly connected data that relational DBs handle poorly
- Build knowledge graphs from unstructured text using LLMs
- Power GraphRAG pipelines that retrieve entity relationships alongside embeddings
- Run graph algorithms (PageRank, community detection) via the Graph Data Science library
- Use LangChain's `Neo4jGraph` and `GraphCypherQAChain` for natural-language graph queries

## Key Concepts
```python
from neo4j import GraphDatabase
from langchain_community.graphs import Neo4jGraph
from langchain_community.chains import GraphCypherQAChain
from langchain_openai import ChatOpenAI

# --- Connect with Python driver ---
driver = GraphDatabase.driver("bolt://localhost:7687", auth=("neo4j", "password"))

# --- Create nodes and relationships with Cypher ---
with driver.session() as session:
    session.run("""
        MERGE (p:Person {name: $name, age: $age})
        MERGE (c:Company {name: $company})
        MERGE (p)-[:WORKS_AT {since: $since}]->(c)
    """, name="Alice", age=30, company="Acme Corp", since=2020)

# --- Query: MATCH pattern ---
with driver.session() as session:
    result = session.run("""
        MATCH (p:Person)-[:WORKS_AT]->(c:Company)
        WHERE c.name = $company
        RETURN p.name AS name, p.age AS age
        ORDER BY p.age DESC
    """, company="Acme Corp")
    for record in result:
        print(f"{record['name']} (age {record['age']})")

# --- Knowledge Graph from text via LLM ---
with driver.session() as session:
    # Store extracted entities and relationships
    session.run("""
        MERGE (e1:Entity {name: $entity1, type: $type1})
        MERGE (e2:Entity {name: $entity2, type: $type2})
        MERGE (e1)-[:RELATION {type: $relation}]->(e2)
    """, entity1="OpenAI", type1="Organization",
         entity2="GPT-4", type2="Model",
         relation="DEVELOPED")

# --- Graph Algorithms via GDS (Graph Data Science) ---
with driver.session() as session:
    # Project an in-memory graph
    session.run("""
        CALL gds.graph.project('myGraph', 'Person', 'KNOWS')
    """)
    # PageRank
    session.run("""
        CALL gds.pageRank.stream('myGraph')
        YIELD nodeId, score
        RETURN gds.util.asNode(nodeId).name AS name, score
        ORDER BY score DESC LIMIT 10
    """)
    # Community detection (Louvain)
    session.run("""
        CALL gds.louvain.stream('myGraph')
        YIELD nodeId, communityId
        RETURN gds.util.asNode(nodeId).name AS name, communityId
        ORDER BY communityId
    """)

# --- LangChain: Natural Language → Cypher ---
graph = Neo4jGraph(url="bolt://localhost:7687", username="neo4j", password="password")
graph.refresh_schema()

chain = GraphCypherQAChain.from_llm(
    llm=ChatOpenAI(model="gpt-4o", temperature=0),
    graph=graph,
    verbose=True,
    return_intermediate_steps=True
)
response = chain.invoke({"query": "Who works at Acme Corp and what is their age?"})
print(response["result"])

# --- GraphRAG: entities + communities for richer context ---
with driver.session() as session:
    # Find entities related to a concept within 2 hops
    result = session.run("""
        MATCH path = (start:Entity {name: $entity})-[*1..2]-(related)
        RETURN [node IN nodes(path) | node.name] AS entities,
               [rel  IN relationships(path) | type(rel)] AS relations
        LIMIT 20
    """, entity="OpenAI")
    for record in result:
        print(record["entities"], "→", record["relations"])

driver.close()
```

## Learning Path
1. Install Neo4j Desktop or run `docker run -p 7474:7687 neo4j:latest`
2. Learn the property graph model: nodes (labels), relationships (types), properties
3. Master Cypher: `MATCH`, `CREATE`, `MERGE`, `WHERE`, `RETURN`, `WITH`, `UNWIND`
4. Use the Neo4j Python driver for programmatic graph management
5. Model a real domain (movies, products, org charts) and write Cypher queries
6. Explore graph algorithms via GDS: PageRank, Louvain, shortest paths
7. Integrate LangChain `Neo4jGraph` and `GraphCypherQAChain` for NL querying
8. Build a knowledge graph extractor that parses text with an LLM and stores triples
9. Implement GraphRAG: retrieve entity neighborhoods as context for LLM answers
10. Scale with Neo4j AuraDB (managed cloud) and learn index + constraint best practices

## What to Build
- [ ] Knowledge graph builder that extracts entities and relations from Wikipedia articles
- [ ] GraphCypherQAChain chatbot that answers questions over a custom graph
- [ ] Fraud detection graph: flag suspicious transaction patterns with Cypher queries
- [ ] Recommendation engine using collaborative filtering paths in the graph
- [ ] GraphRAG pipeline: vector search for candidates + graph traversal for context
- [ ] Community detection report: visualize entity clusters using Louvain algorithm

## Related Folders
- `databases/qdrant-main/` — combine vector + graph for GraphRAG (dual-store pattern)
- `databases/postgresql-pgvector-main/` — SQL-based alternative with vector support
- `rag-advanced/rag-pipeline-main/` — full RAG pipeline that can use Neo4j as retriever
