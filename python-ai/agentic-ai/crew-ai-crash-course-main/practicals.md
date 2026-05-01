# CrewAI Hands-On Projects

A collection of practical CrewAI projects to build and extend. Each project includes
objective, agents, tasks, setup hints, and extension ideas.

---

## Project 1: AI Research Team

**Objective**: Build a three-agent system that researches a topic, analyzes findings,
and produces a polished report.

**Agents**:
- Web Researcher - searches and gathers raw information using SerperDevTool
- Research Analyst - filters, validates, and structures the raw findings
- Report Writer - transforms the analysis into a professional written report

**Tasks**:
1. Search the web for recent news and publications on the topic
2. Analyze relevance, accuracy, and significance of each finding
3. Write a structured report with executive summary, findings, and conclusions

**Setup Steps**:
`ash
pip install crewai crewai-tools
export OPENAI_API_KEY=your-key
export SERPER_API_KEY=your-serper-key
`

**Starter Code Hint**:
`python
from crewai import Agent, Task, Crew
from crewai_tools import SerperDevTool

crew = Crew(
    agents=[researcher, analyst, writer],
    tasks=[search_task, analyze_task, report_task],
    verbose=True,
    memory=True,
    output_log_file="research_log.txt"
)
result = crew.kickoff(inputs={"topic": "Quantum Computing Breakthroughs 2024"})
`

**Extensions**:
- Add a Fact Checker agent to verify claims before writing
- Use output_file to save the report as a markdown file
- Add human_input=True on the report task for editorial review

---

## Project 2: Automated Code Review Crew

**Objective**: Automatically review a Python codebase for bugs, security issues,
and style violations, then generate a fix.

**Agents**:
- Code Reviewer - identifies logic errors and code smells
- Security Auditor - checks for OWASP vulnerabilities, injection risks, auth flaws
- Code Fixer - rewrites the code addressing all identified issues
- Test Writer - writes pytest tests for the fixed code

**Tasks**:
1. Review provided code for quality and logic issues
2. Audit for security vulnerabilities
3. Fix all identified issues while preserving functionality
4. Write unit tests covering the fixed code

**Setup Steps**:
`ash
pip install crewai langchain-openai
`

**Key Configuration**:
`python
fix_task = Task(
    description="Fix all issues identified in the review and security audit.",
    expected_output="Corrected Python code with inline comments explaining each fix.",
    agent=fixer,
    context=[review_task, security_task],
    output_file="fixed_code.py"
)
`

**Extensions**:
- Load code from a GitHub repository using GithubSearchTool
- Add a Documentation Writer agent to generate docstrings
- Implement a Flow that loops until all tests pass

---

## Project 3: Blog Writer Crew

**Objective**: End-to-end automated blog post creation from topic to publication-ready content.

**Agents**:
- SEO Researcher - finds target keywords, competitor content, and search intent
- Content Writer - drafts the blog post with proper structure and keyword placement
- Editor - refines tone, grammar, clarity, and ensures style guide compliance

**Tasks**:
1. Research keywords and analyze top 3 competing posts for the target topic
2. Write a 1,000-word SEO-optimized blog post using the research
3. Edit and polish the draft for publication

**Setup**:
`python
seo_researcher = Agent(
    role="SEO Content Strategist",
    goal="Identify high-value keywords and content angles for maximum search visibility",
    backstory="5 years at an SEO agency, managed content strategy for Fortune 500 blogs.",
    tools=[SerperDevTool(), ScrapeWebsiteTool()]
)
`

**Extensions**:
- Add human_input=True on the edit task for final approval
- Use kickoff_for_each() to generate posts for multiple topics in bulk
- Save final posts with output_file in a /posts/ directory

---

## Project 4: Data Analyst Crew

**Objective**: Automated data analysis pipeline that fetches data, performs statistical
analysis, and generates a visual report with insights.

**Agents**:
- Data Fetcher - retrieves data from APIs or files using custom tools
- Statistical Analyzer - runs descriptive stats, trend analysis, anomaly detection
- Insight Generator - produces business recommendations from analytical findings
- Visualizer - creates matplotlib/plotly chart descriptions or actual chart code

**Tasks**:
1. Fetch and clean the target dataset
2. Perform statistical analysis (mean, median, trends, correlations, outliers)
3. Generate visualizations (chart type suggestions with data)
4. Write an insights report with actionable recommendations

**Custom Tool Example**:
`python
@tool("API Data Fetcher")
def fetch_api_data(endpoint: str, params: str) -> str:
    """Fetches JSON data from a REST API endpoint. params should be URL query string."""
    import requests
    response = requests.get(endpoint, params=dict(p.split('=') for p in params.split('&')))
    return response.text[:3000]
`

**Extensions**:
- Integrate with pandas and matplotlib via CodeInterpreterTool
- Schedule the crew to run daily with a cron job
- Send the report via email using a custom email tool

---

## Project 5: Customer Support Crew with Escalation

**Objective**: Multi-tier customer support system that handles queries, escalates
complex cases, and generates resolution summaries.

**Agents**:
- Tier 1 Support Agent - handles common queries using a knowledge base tool
- Technical Specialist - resolves complex technical issues (only gets escalated cases)
- Support Manager - reviews resolutions and generates CSAT-optimized summaries

**Tasks**:
1. Analyze the customer query and attempt resolution using knowledge base
2. If unresolved: escalate to technical specialist for deep investigation
3. Generate a customer-friendly resolution summary

**Escalation Logic with Flow**:
`python
@router(tier1_response)
def escalation_check(self):
    if "unresolved" in self.state.tier1_response.lower():
        return "escalate"
    return "resolve"
`

**Extensions**:
- Add sentiment analysis tool to prioritize angry customers
- Connect to a CRM via custom API tool
- Track resolution time metrics with callbacks

---

## Project 6: Social Media Content Crew

**Objective**: Generate a week's worth of social media content across platforms from a single topic.

**Agents**:
- Trend Researcher - identifies trending hashtags and content formats per platform
- Content Creator - writes platform-specific posts (Twitter/X, LinkedIn, Instagram)
- Hashtag Strategist - recommends optimal hashtag sets per post
- Content Calendar Manager - schedules and formats the content calendar

**Tasks**:
1. Research trending topics and formats for Twitter, LinkedIn, and Instagram
2. Create 3 posts per platform (9 total) tailored to each platform's tone
3. Generate optimal hashtag sets for each post
4. Compile into a formatted content calendar spreadsheet

**Platform Customization**:
`python
content_task = Task(
    description=(
        "Create platform-specific posts for {topic}. "
        "Twitter: 280 chars, punchy, 2-3 hashtags. "
        "LinkedIn: 150-300 words, professional tone, industry insights. "
        "Instagram: 100-150 words, visual description + 10 hashtags."
    ),
    ...
)
`

**Extensions**:
- Add image prompt generation for Midjourney/DALL-E
- Use kickoff_for_each() for multiple campaign topics
- Auto-post using platform APIs via custom tools

---

## Project 7: Product Review Analyzer Crew

**Objective**: Scrape and analyze product reviews to extract sentiment, common issues,
and improvement recommendations.

**Agents**:
- Review Scraper - collects reviews from Amazon/G2/Trustpilot using scraping tools
- Sentiment Analyzer - categorizes reviews by sentiment and identifies themes
- Product Manager Advisor - translates findings into product improvement roadmap

**Tasks**:
1. Scrape 50+ reviews for a given product URL
2. Perform thematic sentiment analysis: positive themes, negative themes, neutral
3. Generate a product improvement roadmap with priority ranking

**Tool Setup**:
`python
from crewai_tools import ScrapeWebsiteTool, WebsiteSearchTool
scraper = ScrapeWebsiteTool()
reviewer_agent = Agent(..., tools=[scraper])
`

**Extensions**:
- Compare reviews across competitor products
- Track sentiment changes over time with long-term memory
- Auto-generate response templates for negative reviews

---

## Project 8: Competitive Intelligence Crew

**Objective**: Monitor and analyze competitors, producing actionable battlecards
and strategic recommendations.

**Agents**:
- Competitive Researcher - searches for competitor news, product updates, pricing
- SWOT Analyst - performs structured SWOT analysis on each competitor
- Strategy Advisor - synthesizes findings into competitive positioning recommendations

**Tasks**:
1. Research competitor across: pricing, features, recent news, customer sentiment
2. Build a SWOT matrix for each competitor
3. Generate a competitive battlecard and positioning strategy

**Dynamic Multi-Competitor Analysis**:
`python
competitors = [
    {"company": "CompetitorA", "product": "ProductX"},
    {"company": "CompetitorB", "product": "ProductY"},
]
results = crew.kickoff_for_each(inputs=competitors)
`

**Extensions**:
- Schedule weekly competitive intelligence reports
- Add RSS feed monitoring tool for real-time competitor news
- Build a Streamlit dashboard to display battlecards

---

## Project 9: Technical Documentation Crew

**Objective**: Automatically generate comprehensive technical documentation for a
codebase or API.

**Agents**:
- Code Analyzer - reads source code and extracts functions, classes, and interfaces
- API Documentation Writer - writes OpenAPI/Swagger-style endpoint documentation
- Tutorial Writer - creates step-by-step tutorials for common use cases
- README Generator - produces a polished project README

**Tasks**:
1. Analyze the codebase structure and extract all public APIs
2. Write API reference documentation for each endpoint/function
3. Create 3 tutorials: Quick Start, Common Use Cases, Advanced Configuration
4. Generate the project README with badges, installation, and usage examples

**File Tool Setup**:
`python
from crewai_tools import DirectoryReadTool, FileReadTool
dir_tool = DirectoryReadTool(directory="./src")
file_tool = FileReadTool()
analyzer_agent = Agent(..., tools=[dir_tool, file_tool])
`

**Extensions**:
- Auto-detect docstring style (Google, NumPy, Sphinx) and maintain consistency
- Generate changelog from git commit history
- Publish docs to GitHub Pages via git automation tool

---

## Project 10: Multi-Language Content Crew

**Objective**: Create content in English and automatically adapt it for 5 additional
languages while preserving cultural nuance.

**Agents**:
- Original Content Creator - writes high-quality content in English
- Translator Team Lead - coordinates translation strategy and terminology consistency
- Cultural Adapter (per language) - adapts idioms and cultural references per locale
- Quality Reviewer - validates translations for accuracy and natural phrasing

**Tasks**:
1. Create original content in English (article, email, or marketing copy)
2. Develop a translation glossary for domain-specific terms
3. Translate and culturally adapt for: Spanish, French, German, Japanese, Portuguese
4. Review each translation for quality and flag issues

**Multi-Language Processing**:
`python
languages = [
    {"target_language": "Spanish", "locale": "Mexico", "formality": "informal"},
    {"target_language": "French", "locale": "France", "formality": "formal"},
    {"target_language": "German", "locale": "Germany", "formality": "formal"},
    {"target_language": "Japanese", "locale": "Japan", "formality": "polite"},
    {"target_language": "Portuguese", "locale": "Brazil", "formality": "informal"},
]
results = crew.kickoff_for_each(inputs=languages)
`

**Extensions**:
- Add back-translation verification to catch mistranslations
- Use locale-specific search tools to verify cultural appropriateness
- Store approved translations in long-term memory as reference glossary

---

## Getting Started Checklist

Before running any project:
- [ ] Python 3.10+ installed
- [ ] Run: pip install crewai crewai-tools langchain-openai
- [ ] Set OPENAI_API_KEY environment variable
- [ ] Set SERPER_API_KEY if using search tools
- [ ] Test with erbose=True to see agent reasoning
- [ ] Start with gpt-3.5-turbo to control costs during development
- [ ] Switch to gpt-4o for production runs

## Debugging Tips

- Enable erbose=2 for maximum logging detail
- Use step_callback to log each agent action to a file
- Check esult.token_usage to monitor and optimize costs
- Reduce max_iter if agents are getting stuck in loops
- Add explicit format requirements in xpected_output if outputs are inconsistent
- Use human_input=True on key tasks when iterating on crew design