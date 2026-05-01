# CrewAI Code Examples

## Example 1: Minimal Two-Agent Crew

The simplest CrewAI setup: two agents, two tasks, sequential execution.

`python
from crewai import Agent, Task, Crew

researcher = Agent(
    role="Researcher",
    goal="Find key facts about the topic",
    backstory="You are a diligent research assistant with expertise in finding accurate information."
)

writer = Agent(
    role="Writer",
    goal="Write a clear summary based on research",
    backstory="You are a professional writer who turns research into engaging content."
)

research_task = Task(
    description="Research the history of Python programming language.",
    expected_output="A bullet list of 5 key milestones in Python's history.",
    agent=researcher
)

write_task = Task(
    description="Write a short blog post about Python's history.",
    expected_output="A 200-word blog post suitable for beginners.",
    agent=writer,
    context=[research_task]
)

crew = Crew(agents=[researcher, writer], tasks=[research_task, write_task], verbose=True)
result = crew.kickoff()
print(result.raw)
`

---

## Example 2: Detailed Agent with Role, Goal, and Backstory

Well-crafted agent personas significantly improve output quality.

`python
from crewai import Agent
from langchain_openai import ChatOpenAI

senior_analyst = Agent(
    role="Senior Financial Analyst",
    goal=(
        "Analyze financial data, identify trends, and provide actionable investment insights "
        "backed by quantitative evidence."
    ),
    backstory=(
        "You have 12 years of experience at Goldman Sachs covering technology stocks. "
        "You are known for your rigorous DCF models and your ability to spot market trends "
        "before they become consensus. You always cite data sources and quantify uncertainty. "
        "You prefer conservative estimates and always flag risks prominently."
    ),
    llm=ChatOpenAI(model_name="gpt-4o", temperature=0.1),
    verbose=True,
    allow_delegation=False,
    max_iter=5
)
`

---

## Example 3: Task with Detailed Description and Expected Output

Precise task definitions produce precise outputs.

`python
from crewai import Task

analysis_task = Task(
    description=(
        "Analyze the provided Q3 2024 earnings data for Tesla (TSLA). "
        "Calculate YoY revenue growth, gross margin, and free cash flow. "
        "Compare these metrics against analyst consensus estimates. "
        "Identify 3 positive and 3 negative signals from the earnings report."
    ),
    expected_output=(
        "A structured report containing: "
        "1) A table with key metrics vs. consensus, "
        "2) YoY change percentages, "
        "3) A 'Positives' section with 3 bullet points, "
        "4) A 'Negatives' section with 3 bullet points, "
        "5) An overall 1-paragraph investment takeaway. "
        "Format in Markdown."
    ),
    agent=senior_analyst,
    output_file="tesla_q3_analysis.md"
)
`

---

## Example 4: Sequential Process Crew

Default process - tasks run in order, each can use prior task output as context.

`python
from crewai import Agent, Task, Crew, Process

# Agents
researcher = Agent(role="Researcher", goal="Gather information", backstory="Expert researcher.")
analyst = Agent(role="Analyst", goal="Analyze data", backstory="Expert data analyst.")
writer = Agent(role="Writer", goal="Write reports", backstory="Expert technical writer.")

# Tasks
t1 = Task(description="Research AI trends in 2024.", expected_output="List of 10 key trends.", agent=researcher)
t2 = Task(description="Analyze the significance of each trend.", expected_output="Analysis of each trend's impact.", agent=analyst, context=[t1])
t3 = Task(description="Write a comprehensive report.", expected_output="A 500-word report in Markdown.", agent=writer, context=[t1, t2])

# Sequential crew
crew = Crew(
    agents=[researcher, analyst, writer],
    tasks=[t1, t2, t3],
    process=Process.sequential,
    verbose=True
)

result = crew.kickoff()
print(result.raw)
`

---

## Example 5: Hierarchical Process Crew

Manager LLM dynamically assigns tasks to the most appropriate agents.

`python
from crewai import Agent, Task, Crew, Process
from langchain_openai import ChatOpenAI

manager_llm = ChatOpenAI(model_name="gpt-4o", temperature=0)

dev = Agent(role="Senior Developer", goal="Write production-quality code", backstory="10 years Python dev.")
qa = Agent(role="QA Engineer", goal="Find and document bugs", backstory="Expert in test automation.")
doc_writer = Agent(role="Technical Writer", goal="Write clear documentation", backstory="5 years writing API docs.")

t1 = Task(description="Implement a REST API endpoint for user authentication.", expected_output="Working Python code.", agent=dev)
t2 = Task(description="Write tests for the authentication endpoint.", expected_output="pytest test suite.", agent=qa)
t3 = Task(description="Document the authentication API.", expected_output="OpenAPI-style documentation.", agent=doc_writer)

crew = Crew(
    agents=[dev, qa, doc_writer],
    tasks=[t1, t2, t3],
    process=Process.hierarchical,
    manager_llm=manager_llm,
    verbose=True
)

result = crew.kickoff()
`

---

## Example 6: Agent with Built-In Tools

Equipping agents with search and scraping capabilities.

`python
from crewai import Agent, Task, Crew
from crewai_tools import SerperDevTool, ScrapeWebsiteTool, FileWriterTool
import os

os.environ["SERPER_API_KEY"] = "your-serper-api-key"

search_tool = SerperDevTool()
scrape_tool = ScrapeWebsiteTool()
file_tool = FileWriterTool()

research_agent = Agent(
    role="Senior Research Specialist",
    goal="Find comprehensive, accurate information from the web",
    backstory=(
        "You are a research specialist with expertise in finding authoritative sources. "
        "You always cross-reference information across multiple sources and prefer "
        "primary sources (official docs, research papers) over secondary ones."
    ),
    tools=[search_tool, scrape_tool, file_tool],
    verbose=True
)

task = Task(
    description="Research the latest developments in quantum computing in 2024.",
    expected_output="A comprehensive summary with 5 key breakthroughs, each with source URL.",
    agent=research_agent,
    output_file="quantum_research.md"
)

crew = Crew(agents=[research_agent], tasks=[task])
result = crew.kickoff()
`

---

## Example 7: Custom @tool Function

Creating domain-specific tools with the @tool decorator.

`python
from crewai.tools import tool
from crewai import Agent, Task, Crew
import requests

@tool("Currency Exchange Rate Fetcher")
def get_exchange_rate(base_currency: str, target_currency: str) -> str:
    """
    Fetches the current exchange rate between two currencies.
    Use this when you need up-to-date forex data.
    Args:
        base_currency: The source currency code (e.g., 'USD', 'EUR')
        target_currency: The destination currency code (e.g., 'GBP', 'JPY')
    Returns:
        Current exchange rate as a string.
    """
    url = f"https://api.exchangerate-api.com/v4/latest/{base_currency}"
    try:
        response = requests.get(url, timeout=10)
        data = response.json()
        rate = data["rates"].get(target_currency, "Not found")
        return f"1 {base_currency} = {rate} {target_currency}"
    except Exception as e:
        return f"Error fetching rate: {str(e)}"

@tool("Stock Price Checker")
def check_stock_price(ticker: str) -> str:
    """
    Returns current stock price and basic info for a given ticker symbol.
    Use for financial analysis tasks requiring current market data.
    """
    return f"Mock: {ticker} is trading at .00 (+2.3% today)"

financial_agent = Agent(
    role="Financial Analyst",
    goal="Provide accurate financial analysis using real-time data",
    backstory="Expert financial analyst with access to market data tools.",
    tools=[get_exchange_rate, check_stock_price]
)
`

---

## Example 8: Task Context Chaining

Passing output from one task as input context to subsequent tasks.

`python
from crewai import Agent, Task, Crew

researcher = Agent(role="Researcher", goal="Gather detailed information", backstory="Research expert.")
summarizer = Agent(role="Summarizer", goal="Condense information clearly", backstory="Expert at summarizing.")
publisher = Agent(role="Publisher", goal="Format content for publication", backstory="Content publisher.")

# Step 1: Research
research_task = Task(
    description="Research everything about large language models (LLMs) released in 2024.",
    expected_output="Detailed notes covering architectures, benchmarks, and key players.",
    agent=researcher
)

# Step 2: Summarize (uses research output as context)
summary_task = Task(
    description="Create a concise summary of the LLM landscape from the research notes.",
    expected_output="A 300-word executive summary highlighting the most significant developments.",
    agent=summarizer,
    context=[research_task]  # Injects research_task output into this task's prompt
)

# Step 3: Publish (uses both previous outputs)
publish_task = Task(
    description="Format the summary as a professional newsletter section with a headline.",
    expected_output="Newsletter-ready content with headline, subheading, and body text in HTML.",
    agent=publisher,
    context=[research_task, summary_task]  # Has access to both prior outputs
)

crew = Crew(agents=[researcher, summarizer, publisher], tasks=[research_task, summary_task, publish_task])
result = crew.kickoff()
`

---

## Example 9: output_file on Task

Automatically saving task output to a file.

`python
from crewai import Agent, Task, Crew

writer = Agent(
    role="Technical Writer",
    goal="Produce well-structured technical documentation",
    backstory="Senior technical writer with 8 years documenting APIs and SDKs."
)

doc_task = Task(
    description=(
        "Write comprehensive API documentation for a REST endpoint that accepts "
        "POST requests with JSON body containing 'username' and 'password' fields, "
        "validates credentials, and returns a JWT token."
    ),
    expected_output=(
        "Complete API documentation including: endpoint URL, HTTP method, request headers, "
        "request body schema, response schema, error codes, and a curl example."
    ),
    agent=writer,
    output_file="api_documentation.md"  # Saved automatically when task completes
)

crew = Crew(agents=[writer], tasks=[doc_task])
result = crew.kickoff()
# api_documentation.md is now written to disk
`

---

## Example 10: Memory-Enabled Crew

Enabling all memory types for cross-run knowledge retention.

`python
from crewai import Agent, Task, Crew
import os

os.environ["OPENAI_API_KEY"] = "your-api-key"

researcher = Agent(
    role="Research Director",
    goal="Build a comprehensive knowledge base about AI topics",
    backstory="Veteran AI researcher who builds on previous findings.",
    memory=True  # Agent-level memory
)

task = Task(
    description="Research and document the latest advances in reinforcement learning from human feedback (RLHF).",
    expected_output="Detailed technical summary with key papers, methods, and applications.",
    agent=researcher
)

crew = Crew(
    agents=[researcher],
    tasks=[task],
    memory=True,          # Enables ALL memory types
    verbose=True,
    embedder={
        "provider": "openai",
        "config": {
            "model": "text-embedding-3-small"
        }
    }
)

result = crew.kickoff()
# On the next run, the crew will remember what it learned this time
`

---

## Example 11: Short-Term Memory Configuration

Short-term memory persists only within the current run.

`python
from crewai import Crew
from crewai.memory import ShortTermMemory
from crewai.memory.storage.rag_storage import RAGStorage

short_term = ShortTermMemory(
    storage=RAGStorage(
        embedder_config={
            "provider": "openai",
            "config": {"model": "text-embedding-3-small"}
        },
        type="short_term",
        path="./memory/"
    )
)

crew = Crew(
    agents=[...],
    tasks=[...],
    memory=True,
    short_term_memory=short_term
)
`

---

## Example 12: Long-Term Memory Configuration

Long-term memory persists across crew runs using SQLite.

`python
from crewai import Crew
from crewai.memory import LongTermMemory
from crewai.memory.storage.ltm_sqlite_storage import LTMSQLiteStorage

long_term = LongTermMemory(
    storage=LTMSQLiteStorage(
        db_path="./crew_memory/long_term.db"
    )
)

crew = Crew(
    agents=[...],
    tasks=[...],
    memory=True,
    long_term_memory=long_term
)
`

---

## Example 13: Entity Memory

Tracking named entities across the crew run.

`python
from crewai import Crew
from crewai.memory import EntityMemory
from crewai.memory.storage.rag_storage import RAGStorage

entity_memory = EntityMemory(
    storage=RAGStorage(
        embedder_config={
            "provider": "openai",
            "config": {"model": "text-embedding-3-small"}
        },
        type="entities",
        path="./memory/"
    )
)

crew = Crew(
    agents=[...],
    tasks=[...],
    memory=True,
    entity_memory=entity_memory
)
# Crew will track people, organizations, and concepts it encounters
`

---

## Example 14: Async Kickoff with kickoff_async()

Non-blocking crew execution for integration with async applications.

`python
import asyncio
from crewai import Agent, Task, Crew

researcher = Agent(role="Researcher", goal="Find information", backstory="Expert researcher.")
task = Task(description="Research Python 3.13 new features.", expected_output="Feature list.", agent=researcher)
crew = Crew(agents=[researcher], tasks=[task])

async def run_research():
    result = await crew.kickoff_async(inputs={"topic": "Python 3.13"})
    print(result.raw)
    return result

async def main():
    # Run multiple crews concurrently
    results = await asyncio.gather(
        run_research(),
        run_research()
    )
    for r in results:
        print(r.raw)

asyncio.run(main())
`

---

## Example 15: Batch Processing with kickoff_for_each_async()

Process multiple inputs concurrently using the same crew definition.

`python
import asyncio
from crewai import Agent, Task, Crew

analyst = Agent(
    role="Market Analyst",
    goal="Analyze market trends for given industry",
    backstory="Expert analyst covering multiple industry sectors."
)

task = Task(
    description="Analyze the current market trends in the {industry} sector. Focus on growth drivers and risks.",
    expected_output="A structured analysis with market size, growth rate, key players, opportunities, and risks.",
    agent=analyst
)

crew = Crew(agents=[analyst], tasks=[task])

industries = [
    {"industry": "Electric Vehicles"},
    {"industry": "Renewable Energy"},
    {"industry": "Artificial Intelligence"},
    {"industry": "Biotechnology"},
    {"industry": "Cybersecurity"}
]

async def main():
    results = await crew.kickoff_for_each_async(inputs=industries)
    for industry_input, result in zip(industries, results):
        print(f"\n=== {industry_input['industry']} ===")
        print(result.raw)

asyncio.run(main())
`

---

## Example 16: Human Input Task

Pausing for human review mid-workflow.

`python
from crewai import Agent, Task, Crew

writer = Agent(
    role="Content Strategist",
    goal="Create compelling marketing content",
    backstory="Marketing expert with 10 years in digital content."
)

draft_task = Task(
    description="Write a marketing email for the launch of our new AI product 'SmartAssist Pro'.",
    expected_output="A complete marketing email with subject line, body, and CTA button text.",
    agent=writer,
    human_input=True  # Pauses here for human to review/edit before continuing
)

approval_task = Task(
    description="Finalize the email based on approved content and format it for Mailchimp.",
    expected_output="HTML-formatted email ready for Mailchimp import.",
    agent=writer,
    context=[draft_task]
)

crew = Crew(agents=[writer], tasks=[draft_task, approval_task], verbose=True)
result = crew.kickoff()
# Execution pauses at draft_task for human review
`

---

## Example 17: CrewAI Flow Pipeline

Orchestrating multiple crews with shared state and conditional routing.

`python
from crewai.flow.flow import Flow, listen, start, router
from pydantic import BaseModel
from crewai import Agent, Task, Crew

class ContentState(BaseModel):
    topic: str = ""
    research_notes: str = ""
    draft_content: str = ""
    quality_score: int = 0
    final_content: str = ""

class ContentCreationFlow(Flow[ContentState]):

    @start()
    def set_topic(self):
        self.state.topic = "The Future of AGI"
        return self.state.topic

    @listen(set_topic)
    def research_phase(self, topic):
        researcher = Agent(role="Researcher", goal="Deep research", backstory="Expert researcher.")
        task = Task(
            description=f"Research {topic} comprehensively.",
            expected_output="Detailed research notes.",
            agent=researcher
        )
        crew = Crew(agents=[researcher], tasks=[task])
        result = crew.kickoff()
        self.state.research_notes = result.raw
        return result.raw

    @listen(research_phase)
    def writing_phase(self, notes):
        writer = Agent(role="Writer", goal="Write engaging content", backstory="Expert writer.")
        task = Task(
            description=f"Write an article using these notes: {notes[:500]}...",
            expected_output="1000-word article in Markdown.",
            agent=writer
        )
        crew = Crew(agents=[writer], tasks=[task])
        result = crew.kickoff()
        self.state.draft_content = result.raw
        self.state.quality_score = 85  # Mock quality check
        return result.raw

    @router(writing_phase)
    def quality_check(self):
        if self.state.quality_score >= 80:
            return "publish"
        return "revise"

    @listen("publish")
    def publish_content(self):
        self.state.final_content = self.state.draft_content
        print("Content published!")
        return self.state.final_content

flow = ContentCreationFlow()
flow.kickoff()
`

---

## Example 18: Research Crew (Researcher + Writer)

A classic two-agent pipeline for content creation.

`python
import os
from crewai import Agent, Task, Crew
from crewai_tools import SerperDevTool

os.environ["OPENAI_API_KEY"] = "your-key"
os.environ["SERPER_API_KEY"] = "your-serper-key"

search_tool = SerperDevTool()

researcher = Agent(
    role="Senior Research Analyst",
    goal="Uncover comprehensive, accurate, and current information on any given topic",
    backstory=(
        "You are a meticulous researcher with a PhD in information science. "
        "You have 8 years of experience synthesizing academic papers, news articles, "
        "and industry reports into clear, actionable insights. You always cite sources."
    ),
    tools=[search_tool],
    verbose=True
)

writer = Agent(
    role="Expert Content Writer",
    goal="Transform research into compelling, well-structured content",
    backstory=(
        "You are a professional writer with bylines in Wired, TechCrunch, and MIT Tech Review. "
        "You excel at making complex topics accessible without sacrificing accuracy. "
        "Your writing is clear, engaging, and always has a strong narrative thread."
    ),
    verbose=True
)

research_task = Task(
    description="Research the impact of AI on software development jobs in 2024-2025.",
    expected_output="Detailed research notes with statistics, expert quotes, and source URLs.",
    agent=researcher
)

write_task = Task(
    description="Write a balanced, well-sourced article about AI's impact on developer jobs.",
    expected_output="A 600-word article with headline, intro, 3 body sections, and conclusion.",
    agent=writer,
    context=[research_task],
    output_file="ai_dev_jobs_article.md"
)

crew = Crew(agents=[researcher, writer], tasks=[research_task, write_task], verbose=True)
result = crew.kickoff()
`

---

## Example 19: Code Review Crew

Multi-agent code review pipeline.

`python
from crewai import Agent, Task, Crew

code_reviewer = Agent(
    role="Principal Software Engineer",
    goal="Identify bugs, security issues, and code quality problems",
    backstory="15-year veteran engineer who has reviewed thousands of PRs at top tech companies.",
    verbose=True
)

security_auditor = Agent(
    role="Application Security Engineer",
    goal="Find security vulnerabilities, injection risks, and authentication flaws",
    backstory="OWASP expert with a background in penetration testing and secure code review.",
    verbose=True
)

code_fixer = Agent(
    role="Senior Developer",
    goal="Fix identified issues while maintaining code style and architecture",
    backstory="Full-stack developer known for clean, well-tested code.",
    verbose=True
)

code_to_review = '''
def login(username, password):
    query = f"SELECT * FROM users WHERE username='{username}' AND password='{password}'"
    result = db.execute(query)
    return result
'''

review_task = Task(
    description=f"Review this code for bugs and quality issues:\n{code_to_review}",
    expected_output="List of issues with severity (High/Medium/Low) and line references.",
    agent=code_reviewer
)

security_task = Task(
    description=f"Audit this code for security vulnerabilities:\n{code_to_review}",
    expected_output="Security vulnerabilities list with OWASP category and exploit description.",
    agent=security_auditor
)

fix_task = Task(
    description="Fix all identified issues in the code.",
    expected_output="Corrected code with comments explaining each fix.",
    agent=code_fixer,
    context=[review_task, security_task],
    output_file="fixed_code.py"
)

crew = Crew(agents=[code_reviewer, security_auditor, code_fixer], tasks=[review_task, security_task, fix_task])
result = crew.kickoff()
`

---

## Example 20: Data Analysis Crew

End-to-end data analysis pipeline with specialized agents.

`python
from crewai import Agent, Task, Crew
from crewai.tools import tool
import json

@tool("CSV Data Loader")
def load_csv_data(file_path: str) -> str:
    """Loads and returns CSV file contents as a formatted string. Use for data analysis tasks."""
    try:
        with open(file_path, 'r') as f:
            return f.read()
    except Exception as e:
        return f"Error: {str(e)}"

data_engineer = Agent(
    role="Data Engineer",
    goal="Load, clean, and prepare data for analysis",
    backstory="Expert in data pipelines and ETL processes with 7 years experience.",
    tools=[load_csv_data]
)

statistician = Agent(
    role="Senior Statistician",
    goal="Perform rigorous statistical analysis and identify meaningful patterns",
    backstory="PhD in Statistics, specialized in time-series analysis and regression modeling."
)

insights_analyst = Agent(
    role="Business Intelligence Analyst",
    goal="Translate statistical findings into business-actionable insights",
    backstory="10 years in BI, expert at turning data into executive-ready recommendations."
)

load_task = Task(
    description="Load and clean the sales data from sales_data.csv. Identify any data quality issues.",
    expected_output="Clean dataset description with summary statistics and data quality report.",
    agent=data_engineer
)

analyze_task = Task(
    description="Perform statistical analysis on the sales data. Calculate trends, seasonality, correlations.",
    expected_output="Statistical summary with key metrics, trend analysis, and anomalies identified.",
    agent=statistician,
    context=[load_task]
)

insights_task = Task(
    description="Create actionable business recommendations based on the analysis.",
    expected_output="Executive summary with 5 data-driven recommendations and projected impact.",
    agent=insights_analyst,
    context=[load_task, analyze_task],
    output_file="sales_insights_report.md"
)

crew = Crew(
    agents=[data_engineer, statistician, insights_analyst],
    tasks=[load_task, analyze_task, insights_task],
    verbose=True,
    memory=True
)
result = crew.kickoff()
`

---

## Quick Reference

### Minimal Crew Template
`python
from crewai import Agent, Task, Crew

agent = Agent(role="Role", goal="Goal", backstory="Backstory")
task = Task(description="Do X", expected_output="Return Y", agent=agent)
crew = Crew(agents=[agent], tasks=[task])
result = crew.kickoff()
print(result.raw)
`

### Dynamic Inputs Template
`python
task = Task(description="Research {topic} in depth.", ...)
crew.kickoff(inputs={"topic": "Machine Learning"})
`

### Batch Processing Template
`python
inputs = [{"company": "Apple"}, {"company": "Google"}, {"company": "Microsoft"}]
results = crew.kickoff_for_each(inputs=inputs)
`