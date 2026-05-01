# 🔍 RAG Advanced Patterns — Beyond Naive Retrieval

## What is Advanced RAG?
Advanced RAG goes beyond naive "chunk → embed → retrieve → generate" pipelines by addressing their core failure modes: poor chunking, low retrieval precision, and context dilution. Techniques like HyDE, multi-query retrieval, reranking, and GraphRAG dramatically improve answer quality, especially for complex multi-hop questions over large document corpora.

## Why Learn It?
- Naive RAG fails on complex queries — advanced patterns close the quality gap
- Reranking alone can improve retrieval precision by 20–40% on benchmarks
- Agentic RAG enables iterative, self-correcting retrieval for deep research tasks
- Essential for production RAG systems where hallucination and recall both matter

## Key Concepts
```python
from langchain.retrievers import MultiQueryRetriever
from langchain.retrievers.document_compressors import CrossEncoderReranker
from langchain_community.cross_encoders import HuggingFaceCrossEncoder
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_community.vectorstores import FAISS

# --- HyDE: generate a hypothetical answer, embed it for retrieval ---
from langchain.prompts import PromptTemplate
from langchain.chains import LLMChain

hyde_prompt = PromptTemplate.from_template(
    "Write a short document that answers: {question}"
)
llm = ChatOpenAI(model="gpt-4o-mini")
hypothetical_doc = (hyde_prompt | llm).invoke({"question": "What causes transformer attention to fail?"})

# Embed the hypothetical doc instead of the raw question
embeddings = OpenAIEmbeddings()
vectorstore = FAISS.load_local("my_index", embeddings)
docs = vectorstore.similarity_search(hypothetical_doc.content, k=5)

# --- Multi-Query Retrieval: LLM generates query variants ---
retriever = MultiQueryRetriever.from_llm(
    retriever=vectorstore.as_retriever(search_kwargs={"k": 5}),
    llm=llm
)
results = retriever.invoke("How does attention scale with sequence length?")

# --- Cross-Encoder Reranking: reorder candidates by relevance ---
reranker_model = HuggingFaceCrossEncoder(model_name="BAAI/bge-reranker-base")
compressor = CrossEncoderReranker(model=reranker_model, top_n=3)
from langchain.retrievers import ContextualCompressionRetriever
reranking_retriever = ContextualCompressionRetriever(
    base_compressor=compressor,
    base_retriever=retriever
)
final_docs = reranking_retriever.invoke("attention scaling")

# --- Parent-Child Document Retrieval ---
from langchain.retrievers import ParentDocumentRetriever
from langchain.storage import InMemoryStore
from langchain.text_splitter import RecursiveCharacterTextSplitter

parent_splitter = RecursiveCharacterTextSplitter(chunk_size=2000)
child_splitter = RecursiveCharacterTextSplitter(chunk_size=400)
store = InMemoryStore()
parent_retriever = ParentDocumentRetriever(
    vectorstore=vectorstore,
    docstore=store,
    child_splitter=child_splitter,
    parent_splitter=parent_splitter,
)
```

## Learning Path
1. `pip install langchain langchain-openai langchain-community faiss-cpu sentence-transformers`
2. Audit a naive RAG pipeline — identify chunking, retrieval, and generation failure modes
3. Implement semantic chunking: split on meaning boundaries rather than fixed token counts
4. Add HyDE and multi-query retrieval; measure recall improvement with RAGAS
5. Layer in cross-encoder reranking + parent-child retrieval for production quality

## What to Build
- [ ] Advanced RAG Q&A over a large PDF corpus with HyDE + reranking
- [ ] Agentic RAG loop: retrieve → reflect → re-query until confident
- [ ] RAGAS evaluation harness comparing naive vs advanced pipeline on the same dataset

## Related Folders
- `generative-ai/llm-evaluation-ragas-main/` — evaluate your advanced RAG with RAGAS metrics
- `nlp/sentence-transformers-main/` — embedding models used in the retrieval stage
- `generative-ai/langchain-main/` — chain orchestration framework used throughout
