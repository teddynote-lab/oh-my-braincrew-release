# Technical Report Checklist

> This template is copied to `.omb/technical-report/REPORT-JOB-TODO.md` at runtime.
> Update continuously during report generation. Check items as completed.

## Report Metadata

- **Target Project**: _(filled at runtime)_
- **Tech Stack**: _(filled at runtime)_
- **Language**: _(filled at runtime)_
- **Started**: _(filled at runtime)_
- **Last Updated**: _(filled at runtime)_

---

## 1. Project Setup

- [ ] Target project path resolved and validated
- [ ] PROJECT.md read and context extracted (or marked as absent)
- [ ] CLAUDE.md read and context extracted (or marked as absent)
- [ ] README.md read as fallback (if no PROJECT.md/CLAUDE.md)
- [ ] PROJECT_CONTEXT summary compiled (max ~2000 words)
- [ ] Tech stack detected (languages, frameworks, build tools)
- [ ] Report language preference confirmed with user
- [ ] Output directory `docs/technical-report/` created
- [ ] TODO file `.omb/technical-report/REPORT-JOB-TODO.md` initialized

## 2. Code Exploration

- [ ] Backend domain explored (services, business logic, middleware)
- [ ] Frontend domain explored (components, state, routing)
- [ ] API domain explored (routes, controllers, OpenAPI specs)
- [ ] Database domain explored (schemas, migrations, ORM models)
- [ ] Infrastructure domain explored (Docker, CI/CD, deployment)
- [ ] Security domain explored (auth, secrets, dependencies)
- [ ] General domain explored (project structure, config, README)
- [ ] All explorer agents returned findings (no timeouts or failures)
- [ ] Findings capped at 20 per domain (no context overflow)

## 3. Knowledge Clustering

- [ ] Findings organized into document categories
- [ ] Empty categories identified and removed
- [ ] Cross-domain relationships mapped (e.g., API ↔ Backend ↔ DB)
- [ ] No findings left unclassified

## 4. User Confirmation

- [ ] Document structure proposed to user
- [ ] User confirmed/modified category list
- [ ] TOC proposed for each category
- [ ] API spec depth level confirmed
- [ ] Mermaid diagram preference confirmed
- [ ] Risk detail level confirmed

## 5. Draft & Feedback

- [ ] Outline drafts generated for all categories
- [ ] User reviewed outlines
- [ ] User feedback incorporated (if any)

## 6. Document Generation

### 6.1 Architecture Documents
- [ ] System overview written with high-level description
- [ ] Component diagram (mermaid) generated and renders correctly
- [ ] Component relationships documented
- [ ] Data flow between components described
- [ ] Design patterns identified and documented
- [ ] Technology choices explained with rationale

### 6.2 Backend Documents
- [ ] Service architecture documented
- [ ] Middleware patterns described
- [ ] Business logic flows explained
- [ ] Error handling patterns documented
- [ ] Configuration management described

### 6.3 Frontend Documents
- [ ] Component hierarchy documented
- [ ] State management patterns described
- [ ] Routing structure documented
- [ ] Build system configuration explained
- [ ] UI/UX patterns identified

### 6.4 API Documents
- [ ] All endpoints listed with HTTP methods and paths
- [ ] Request/response schemas documented (at confirmed depth)
- [ ] Authentication/authorization patterns described
- [ ] Error response format documented
- [ ] Rate limiting/throttling documented (if applicable)
- [ ] API versioning strategy documented (if applicable)

### 6.5 Database Documents
- [ ] Schema design documented
- [ ] ER diagram (mermaid) generated and renders correctly
- [ ] Table/collection inventory with columns/fields
- [ ] Index strategy documented
- [ ] Migration patterns described
- [ ] Query patterns and optimization notes

### 6.6 Infrastructure Documents
- [ ] Deployment topology documented
- [ ] Deployment topology diagram (mermaid) renders correctly
- [ ] CI/CD pipeline described
- [ ] Container configuration documented (if applicable)
- [ ] Environment management (dev/staging/prod) described
- [ ] Monitoring and alerting setup documented

### 6.7 Security Documents
- [ ] Authentication flow documented
- [ ] Auth flow diagram (mermaid) renders correctly
- [ ] Authorization model described (RBAC, ABAC, etc.)
- [ ] Secret management approach documented
- [ ] OWASP top 10 considerations addressed
- [ ] Dependency audit results included

### 6.8 Features Documents
- [ ] All major features identified and defined
- [ ] Feature operation flows described
- [ ] User journey / user flow documented
- [ ] Feature dependencies mapped
- [ ] Feature-to-code mapping provided (which files implement what)

### 6.9 Risks Documents
- [ ] Risk matrix includes all severity levels (P0, P1, P2, P3)
- [ ] Each risk has: description, impact, likelihood, mitigation
- [ ] P0/P1 risks have actionable mitigation strategies
- [ ] Improvement roadmap with prioritized items
- [ ] Risk-to-code mapping (which files are affected)

### 6.10 Lessons Learned Documents
- [ ] Code patterns identified (good practices in the codebase)
- [ ] Anti-patterns documented with examples
- [ ] Improvement suggestions with rationale
- [ ] Cross-domain insights (patterns that span multiple layers)
- [ ] Technical debt items cataloged

### 6.11 Master Document (PROJECT-REPORT.md)
- [ ] Project name and overview (2-3 paragraphs)
- [ ] Tech stack summary table
- [ ] Architecture overview mermaid diagram
- [ ] Key features summary with brief descriptions
- [ ] Risk summary (P0-P3 counts)
- [ ] Document index table with links to ALL sub-domain docs
- [ ] All relative links are valid and point to correct files

## 7. Cross-cutting Quality

- [ ] All mermaid diagrams use valid syntax
- [ ] All cross-document links (`[text](relative/path.md)`) are valid
- [ ] Every `.md` file is under 500 lines
- [ ] Numbering is consistent (01-, 02-, 03-...)
- [ ] Numbering follows logical reading order (book TOC style)
- [ ] Only `PROJECT-REPORT.md` sits at `docs/technical-report/` root
- [ ] All sub-domain docs are inside subdirectories
- [ ] Report language is consistent throughout all documents
- [ ] No placeholder text left (e.g., "TODO", "TBD", "{PLACEHOLDER}")
- [ ] Code snippets use correct language identifiers in fenced blocks

## 8. Review Iterations

### Iteration 1: Architecture Review
- [ ] Review completed by critic agent
- [ ] Findings documented: ___ critical, ___ important, ___ minor
- [ ] Improvements applied
- [ ] TODO updated

### Iteration 2: Features Review
- [ ] Review completed by reviewer agent
- [ ] Findings documented: ___ critical, ___ important, ___ minor
- [ ] Improvements applied
- [ ] TODO updated

### Iteration 3: API Review
- [ ] Review completed by api-specialist agent
- [ ] Findings documented: ___ critical, ___ important, ___ minor
- [ ] Improvements applied
- [ ] TODO updated

### Iteration 4: Database & Infra Review (if needed)
- [ ] Review completed by db-specialist agent
- [ ] Findings documented: ___ critical, ___ important, ___ minor
- [ ] Improvements applied
- [ ] TODO updated

### Iteration 5: Security & Risks Review (if needed)
- [ ] Review completed by security-reviewer agent
- [ ] Findings documented: ___ critical, ___ important, ___ minor
- [ ] Improvements applied
- [ ] TODO updated

### Iteration 6: Lessons Learned Review (if needed)
- [ ] Review completed by reviewer (opus) agent
- [ ] Findings documented: ___ critical, ___ important, ___ minor
- [ ] Improvements applied
- [ ] TODO updated

### Iteration 7: Final Polish (if needed)
- [ ] Review completed by reviewer (haiku) agent
- [ ] Cross-document consistency verified
- [ ] Link integrity verified
- [ ] 500-line limit compliance verified
- [ ] Numbering correctness verified
- [ ] TODO updated

## 9. Completion

- [ ] All critical checklist items checked
- [ ] Completion summary reported to user
- [ ] Result reported (DONE / DONE_WITH_CONCERNS / FAILED) in final output
