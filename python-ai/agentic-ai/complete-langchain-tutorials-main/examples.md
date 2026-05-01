# Complete LangChain Tutorials — Code Examples

## Example 1: PyPDFLoader
```python
from langchain_community.document_loaders import PyPDFLoader

loader = PyPDFLoader("document.pdf")
pages = loader.load()  # Returns List[Document]

print(f"Total pages: {len(pages)}")
print(f"First page preview: {pages[0].page_content[:200]}")
print(f"Metadata: {pages[0].metadata}")  # {'source': 'document.pdf', 'page': 0}

# Load and split in one step
pages_split = loader.load_and_split()
```

## Example 2: WebBaseLoader
```python
from langchain_community.document_loaders import WebBaseLoader
import bs4

# Load a single URL
loader = WebBaseLoader("https://en.wikipedia.org/wiki/Python_(programming_language)")
docs = loader.load()

print(f"Content length: {len(docs[0].page_content)}")
print(f"Source: {docs[0].metadata['source']}")

# Load with BeautifulSoup filtering
loader = WebBaseLoader(
    web_paths=["https://python.org"],
    bs_kwargs=dict(parse_only=bs4.SoupStrainer(class_=("entry-content",)))
)
filtered_docs = loader.load()
```

## Example 3: RecursiveCharacterTextSplitter
```python
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFLoader

loader = PyPDFLoader("long_document.pdf")
raw_docs = loader.load()

splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
    add_start_index=True
)

chunks = splitter.split_documents(raw_docs)
print(f"Original pages: {len(raw_docs)}")
print(f"After splitting: {len(chunks)} chunks")
print(f"Sample chunk metadata: {chunks[0].metadata}")
print(f"Sample chunk length: {len(chunks[0].page_content)}")
```

## Example 4: OpenAIEmbeddings
```python
from langchain_openai import OpenAIEmbeddings
import numpy as np

embeddings = OpenAIEmbeddings(model="text-embedding-3-small")

text = "LangChain is a framework for building LLM applications."
vector = embeddings.embed_query(text)
print(f"Embedding dimensions: {len(vector)}")  # 1536

texts = ["Python is great", "JavaScript is versatile", "Rust is fast"]
vectors = embeddings.embed_documents(texts)
print(f"Batch embeddings: {len(vectors)} x {len(vectors[0])}")

def cosine_similarity(a, b):
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

sim = cosine_similarity(vectors[0], vectors[1])
print(f"Similarity Python vs JavaScript: {sim:.3f}")
```

## Example 5: HuggingFaceEmbeddings (Local, Free)
```python
from langchain_huggingface import HuggingFaceEmbeddings

# Free local embeddings — no API key required
embeddings = HuggingFaceEmbeddings(
    model_name="sentence-transformers/all-MiniLM-L6-v2",
    model_kwargs={"device": "cpu"},
    encode_kwargs={"normalize_embeddings": True}
)

texts = ["What is machine learning?", "ML is a subset of AI"]
vectors = embeddings.embed_documents(texts)
print(f"Local embedding dimensions: {len(vectors[0])}")  # 384
```

## Example 6: Chroma Vector Store
```python
from langchain_chroma import Chroma
from langchain_openai import OpenAIEmbeddings
from langchain_community.document_loaders import TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter

loader = TextLoader("knowledge_base.txt")
docs = loader.load()
splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
chunks = splitter.split_documents(docs)

embeddings = OpenAIEmbeddings()
vectorstore = Chroma.from_documents(
    documents=chunks,
    embedding=embeddings,
    persist_directory="./chroma_db"
)

results = vectorstore.similarity_search("What is the main topic?", k=3)
for doc in results:
    print(f"Source: {doc.metadata['source']}")
    print(f"Content: {doc.page_content[:100]}...")
    print("---")
```

## Example 7: FAISS Vector Store
```python
from langchain_community.vectorstores import FAISS
from langchain_openai import OpenAIEmbeddings

texts = [
    "Python is a high-level programming language",
    "Machine learning uses algorithms to learn from data",
    "Neural networks are inspired by the human brain",
    "LangChain makes building LLM apps easier",
    "Vector databases store embeddings for similarity search"
]

embeddings = OpenAIEmbeddings()
vectorstore = FAISS.from_texts(texts, embeddings)

results = vectorstore.similarity_search_with_score("neural networks AI", k=2)
for doc, score in results:
    print(f"Score: {score:.4f} | Content: {doc.page_content}")

# Save and reload
vectorstore.save_local("faiss_index")
loaded = FAISS.load_local("faiss_index", embeddings, allow_dangerous_deserialization=True)
```

## Example 8: VectorStoreRetriever
```python
from langchain_chroma import Chroma
from langchain_openai import OpenAIEmbeddings

vectorstore = Chroma(persist_directory="./chroma_db", embedding_function=OpenAIEmbeddings())

# Basic similarity retriever
retriever = vectorstore.as_retriever(
    search_type="similarity",
    search_kwargs={"k": 4}
)

# MMR retriever for diverse results
mmr_retriever = vectorstore.as_retriever(
    search_type="mmr",
    search_kwargs={"k": 4, "fetch_k": 20, "lambda_mult": 0.5}
)

# Score threshold retriever
threshold_retriever = vectorstore.as_retriever(
    search_type="similarity_score_threshold",
    search_kwargs={"score_threshold": 0.7}
)

relevant_docs = retriever.invoke("What is machine learning?")
print(f"Retrieved {len(relevant_docs)} documents")
```

## Example 9: MultiQueryRetriever
```python
from langchain.retrievers import MultiQueryRetriever
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_chroma import Chroma
import logging

logging.basicConfig()
logging.getLogger("langchain.retrievers.multi_query").setLevel(logging.INFO)

vectorstore = Chroma(persist_directory="./chroma_db", embedding_function=OpenAIEmbeddings())
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

retriever = MultiQueryRetriever.from_llm(
    retriever=vectorstore.as_retriever(),
    llm=llm
)

# Generates 3 variations of your query and merges unique results
docs = retriever.invoke("How does machine learning work?")
print(f"Retrieved {len(docs)} unique documents across all query variations")
```

## Example 10: ContextualCompressionRetriever
```python
from langchain.retrievers import ContextualCompressionRetriever
from langchain.retrievers.document_compressors import LLMChainExtractor
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_chroma import Chroma

vectorstore = Chroma(persist_directory="./chroma_db", embedding_function=OpenAIEmbeddings())
base_retriever = vectorstore.as_retriever(search_kwargs={"k": 4})

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)
compressor = LLMChainExtractor.from_llm(llm)

compression_retriever = ContextualCompressionRetriever(
    base_compressor=compressor,
    base_retriever=base_retriever
)

compressed_docs = compression_retriever.invoke("What are the main benefits?")
for doc in compressed_docs:
    print(f"Compressed: {doc.page_content}")
```

## Example 11: Basic RAG Chain
```python
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_chroma import Chroma
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough

vectorstore = Chroma(persist_directory="./chroma_db", embedding_function=OpenAIEmbeddings())
retriever = vectorstore.as_retriever(search_kwargs={"k": 4})

def format_docs(docs):
    return "\n\n".join(doc.page_content for doc in docs)

prompt = ChatPromptTemplate.from_messages([
    ("system", """You are an assistant. Answer using ONLY the provided context.
If the answer is not in the context, say "I don't have that information."

Context:
{context}"""),
    ("human", "{question}")
])

llm = ChatOpenAI(model="gpt-4o-mini")

rag_chain = (
    {"context": retriever | format_docs, "question": RunnablePassthrough()}
    | prompt
    | llm
    | StrOutputParser()
)

answer = rag_chain.invoke("What is the main purpose of this document?")
print(answer)
```

## Example 12: Conversational RAG with History
```python
from langchain.chains import create_history_aware_retriever, create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.chat_history import InMemoryChatMessageHistory
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_chroma import Chroma

llm = ChatOpenAI(model="gpt-4o-mini")
vectorstore = Chroma(persist_directory="./chroma_db", embedding_function=OpenAIEmbeddings())
retriever = vectorstore.as_retriever()

contextualize_prompt = ChatPromptTemplate.from_messages([
    ("system", "Given chat history and question, rephrase to standalone question."),
    MessagesPlaceholder("chat_history"),
    ("human", "{input}")
])
history_aware_retriever = create_history_aware_retriever(llm, retriever, contextualize_prompt)

qa_prompt = ChatPromptTemplate.from_messages([
    ("system", "Answer using context:\n\n{context}"),
    MessagesPlaceholder("chat_history"),
    ("human", "{input}")
])
qa_chain = create_stuff_documents_chain(llm, qa_prompt)
rag_chain = create_retrieval_chain(history_aware_retriever, qa_chain)

store = {}
def get_history(session_id):
    if session_id not in store:
        store[session_id] = InMemoryChatMessageHistory()
    return store[session_id]

conversational_rag = RunnableWithMessageHistory(
    rag_chain, get_history,
    input_messages_key="input",
    history_messages_key="chat_history",
    output_messages_key="answer"
)

config = {"configurable": {"session_id": "user1"}}
r1 = conversational_rag.invoke({"input": "What is this document about?"}, config=config)
r2 = conversational_rag.invoke({"input": "Tell me more about that."}, config=config)
print(r2["answer"])
```

## Example 13: SQLDatabase Connection
```python
from langchain_community.utilities import SQLDatabase

db = SQLDatabase.from_uri("sqlite:///employees.db")

print(db.dialect)                    # sqlite
print(db.get_usable_table_names())   # ['employees', 'departments', ...]
print(db.get_table_info())           # Full schema with sample rows
```

## Example 14: create_sql_agent
```python
from langchain_community.agent_toolkits import create_sql_agent
from langchain_community.utilities import SQLDatabase
from langchain_openai import ChatOpenAI

db = SQLDatabase.from_uri("sqlite:///chinook.db")
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

agent = create_sql_agent(
    llm=llm,
    db=db,
    agent_type="openai-tools",
    verbose=True
)

result = agent.invoke({"input": "How many employees are there?"})
print(result["output"])
```

## Example 15: Natural Language to SQL Chain
```python
from langchain.chains import create_sql_query_chain
from langchain_community.utilities import SQLDatabase
from langchain_community.tools import QuerySQLDataBaseTool
from langchain_openai import ChatOpenAI
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_core.prompts import PromptTemplate
from operator import itemgetter

db = SQLDatabase.from_uri("sqlite:///chinook.db")
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

write_query = create_sql_query_chain(llm, db)
execute_query = QuerySQLDataBaseTool(db=db)

answer_template = """Given the question, SQL query, and result, answer the question.
Question: {question}
SQL Query: {query}
SQL Result: {result}
Answer: """

answer = PromptTemplate.from_template(answer_template) | llm | StrOutputParser()

full_chain = (
    RunnablePassthrough.assign(query=write_query).assign(
        result=itemgetter("query") | execute_query
    )
    | answer
)

response = full_chain.invoke({"question": "How many unique customers are there?"})
print(response)
```

## Example 16: DuckDuckGo Search Tool
```python
from langchain_community.tools import DuckDuckGoSearchResults
from langchain_community.utilities import DuckDuckGoSearchAPIWrapper

wrapper = DuckDuckGoSearchAPIWrapper(max_results=3)
search = DuckDuckGoSearchResults(api_wrapper=wrapper)

result = search.invoke("LangChain latest features 2024")
print(result)  # JSON with title, link, snippet for each result
```

## Example 17: Wikipedia Tool
```python
from langchain_community.tools import WikipediaQueryRun
from langchain_community.utilities import WikipediaAPIWrapper

wikipedia = WikipediaQueryRun(
    api_wrapper=WikipediaAPIWrapper(top_k_results=2, doc_content_chars_max=1000)
)

result = wikipedia.invoke("Transformer neural network architecture")
print(result[:500])
```

## Example 18: create_react_agent
```python
from langchain.agents import create_react_agent
from langchain_community.tools import DuckDuckGoSearchResults, WikipediaQueryRun
from langchain_community.utilities import WikipediaAPIWrapper
from langchain_openai import ChatOpenAI
from langchain import hub

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)
tools = [
    DuckDuckGoSearchResults(),
    WikipediaQueryRun(api_wrapper=WikipediaAPIWrapper())
]

prompt = hub.pull("hwchase17/react")
agent = create_react_agent(llm=llm, tools=tools, prompt=prompt)
print("Agent created successfully")
print(f"Tools available: {[t.name for t in tools]}")
```

## Example 19: AgentExecutor
```python
from langchain.agents import AgentExecutor, create_react_agent
from langchain_community.tools import DuckDuckGoSearchResults
from langchain_openai import ChatOpenAI
from langchain import hub

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)
tools = [DuckDuckGoSearchResults()]
prompt = hub.pull("hwchase17/react")
agent = create_react_agent(llm=llm, tools=tools, prompt=prompt)

agent_executor = AgentExecutor(
    agent=agent,
    tools=tools,
    verbose=True,
    max_iterations=5,
    handle_parsing_errors=True
)

result = agent_executor.invoke({
    "input": "What is the current version of Python and when was it released?"
})
print(result["output"])
```

## Example 20: LangServe FastAPI App
```python
from fastapi import FastAPI
from langserve import add_routes
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

app = FastAPI(title="LangChain API", version="1.0")

llm = ChatOpenAI(model="gpt-4o-mini")
prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant."),
    ("human", "{input}")
])
chain = prompt | llm | StrOutputParser()

add_routes(app, chain, path="/chat")

# Run: uvicorn main:app --host 0.0.0.0 --port 8000
# Playground: http://localhost:8000/chat/playground
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

## Example 21: Custom Tool with Optional Args
```python
from langchain_core.tools import tool
from typing import Optional
import json

@tool
def get_company_info(company_name: str, info_type: Optional[str] = "all") -> str:
    """Retrieve information about a company.
    
    Args:
        company_name: The name of the company to look up
        info_type: Type of info: 'all', 'revenue', 'employees', 'founded'
    
    Returns:
        JSON string with company information
    """
    companies = {
        "OpenAI": {"founded": 2015, "employees": 700, "revenue": "N/A"},
        "Google": {"founded": 1998, "employees": 180000, "revenue": "280B USD"},
    }
    
    data = companies.get(company_name, {"error": f"Company {company_name} not found"})
    
    if info_type != "all" and info_type in data:
        return json.dumps({info_type: data[info_type]})
    return json.dumps(data)

print(get_company_info.invoke({"company_name": "OpenAI", "info_type": "founded"}))
```

## Example 22: Multi-Tool Agent with create_openai_tools_agent
```python
from langchain.agents import AgentExecutor, create_openai_tools_agent
from langchain_community.tools import DuckDuckGoSearchResults, WikipediaQueryRun
from langchain_community.utilities import WikipediaAPIWrapper
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

@tool
def calculator(expression: str) -> str:
    """Evaluate mathematical expressions. Input should be a valid Python math expression."""
    try:
        result = eval(expression, {"__builtins__": {}}, {"abs": abs, "round": round})
        return str(result)
    except Exception as e:
        return f"Error: {str(e)}"

tools = [
    DuckDuckGoSearchResults(),
    WikipediaQueryRun(api_wrapper=WikipediaAPIWrapper()),
    calculator
]

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)
prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful research assistant with access to search, Wikipedia, and a calculator."),
    ("human", "{input}"),
    MessagesPlaceholder(variable_name="agent_scratchpad")
])

agent = create_openai_tools_agent(llm=llm, tools=tools, prompt=prompt)
executor = AgentExecutor(agent=agent, tools=tools, verbose=True, max_iterations=8)

result = executor.invoke({
    "input": "What year was Python created, and how many years ago was that from 2024?"
})
print(result["output"])
```