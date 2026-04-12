# oh-my-braincrew (omb)

[![Release](https://img.shields.io/github/v/release/teddynote-lab/oh-my-braincrew-release?style=flat-square)](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-blue?style=flat-square)](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest)
[![Python](https://img.shields.io/badge/python-%3E%3D3.12-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-harness-cc785c?style=flat-square&logo=anthropic&logoColor=white)](https://docs.anthropic.com/en/docs/claude-code)
[![License](https://img.shields.io/badge/license-Apache--2.0-green?style=flat-square)](LICENSE)

**[English](README.md)** | **[한국어](README-ko.md)**

[Claude Code](https://docs.anthropic.com/en/docs/claude-code)를 위한 멀티 에이전트 오케스트레이션 하네스.

> 위임하고, 조율하고, 검증하라 — 직접 구현하지 마라.

## 설치

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/teddynote-lab/oh-my-braincrew-release/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/teddynote-lab/oh-my-braincrew-release/main/install.ps1 | iex
```

### 수동 다운로드

| 플랫폼 | 아키텍처 | 바이너리 |
|--------|---------|---------|
| macOS | Apple Silicon (arm64) | [`oh-my-braincrew-v0.1.5-darwin-arm64`](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest) |
| Linux | x86_64 | [`oh-my-braincrew-v0.1.5-linux-amd64`](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest) |
| Windows | x86_64 | [`oh-my-braincrew-v0.1.5-windows-amd64.exe`](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest) |

### 업데이트 / 제거

```bash
omb update                    # 바이너리 및 하네스 파일 업데이트
omb init                      # 하네스 파일만 재설치
```

```bash
rm ~/.local/bin/oh-my-braincrew ~/.local/bin/omb   # 바이너리 제거
```

### CLI 명령어

| 명령어 | 설명 |
|--------|------|
| `omb init [path]` | 최신 릴리즈에서 하네스 파일 다운로드 및 설치 |
| `omb update [path]` | 바이너리 업데이트 및 하네스 파일 갱신 |
| `omb version` | 설치된 버전 출력 |

## 초기 설정

설치 후 프로젝트에서 초기화하고 설정 마법사를 실행합니다:

```bash
cd /path/to/your/project
omb init
```

```
> /omb:setup
```

설정 마법사가 수행하는 작업:
- `.omb/` 디렉토리 구조 생성 (plans, todo, interviews)
- 프로젝트에 맞는 `CLAUDE.md` 생성
- `.claude/settings.json`에 hooks 및 권한 설정

## 추천 워크플로우

전체 개발 사이클을 단계별로 실행하거나 개별적으로 호출할 수 있습니다.

```
# 1. 구조화된 인터뷰로 요구사항 수집
> /omb:interview

# 2. 구현 계획 생성
> /omb:plan

# 3. 멀티 에이전트로 계획 리뷰 및 점수화
> /omb:plan-review

# 4. TDD 에이전트로 계획 실행
> /omb:run

# 5. 구현 결과 검증
> /omb:verify

# 6. 문서 생성
> /omb:doc

# 7. Pull Request 생성
> /omb:pr

# 8. 릴리즈
> /omb:release patch
```

| # | 명령어 | 설명 |
|---|--------|------|
| 1 | `/omb:interview` | 요구사항 인터뷰. `.omb/interviews/`에 저장 |
| 2 | `/omb:plan` | 구현 계획 생성. `.omb/plans/`에 저장 |
| 3 | `/omb:plan-review` | 멀티 에이전트 계획 리뷰 및 정량적 점수화 |
| 4 | `/omb:run [plan]` | TDD 에이전트로 계획 실행. `.omb/todo/`에서 진행 추적 |
| 5 | `/omb:verify [plan]` | 병렬 검증자를 통한 구현 후 검증 |
| 6 | `/omb:doc` | 문서 생성 또는 업데이트 |
| 7 | `/omb:pr` | lint 게이트가 포함된 GitHub PR 생성 |
| 8 | `/omb:release` | 버전 범프, 변경 로그, 태그, GitHub Release, CI 빌드 |

## 명령어 목록

### 워크플로우 명령어

#### `/omb:interview` — 요구사항 인터뷰

기술 스택, 구현 선택지, 설계 선호도를 다루는 최대 15개의 다차원 질문을 합니다. 요약은 `.omb/interviews/`에 저장됩니다.

```
> /omb:interview
# 인터뷰어가 기능 요구사항에 대한 구조화된 질문을 합니다
# 출력: .omb/interviews/2026-04-13-user-auth.md
```

#### `/omb:plan` — 구현 계획

도메인 분해, 에이전트 위임, TDD 전략, 리스크 분석이 포함된 상세 계획을 생성합니다. 품질 게이트를 통과할 때까지 평가-개선 루프를 실행합니다.

```
> /omb:plan
# 코드베이스 탐색 → 계획 작성 → 루브릭 평가 → 개선 → 전달
# 출력: .omb/plans/2026-04-13-user-auth-flow.md
```

#### `/omb:plan-review` — 계획 리뷰

3-12명의 도메인 리뷰어를 병렬로 조립하고, 정량적 평가를 실행하며, P0-P3 이슈 트래킹으로 합의를 도출합니다.

```
> /omb:plan-review
# 다수의 에이전트가 독립적으로 리뷰 → 합의 도출 → 개선
```

#### `/omb:run` — 계획 실행

계획에서 TODO 체크리스트를 파싱하고, 도메인 에이전트에 위임하며, TDD를 강제하고, 진행 상황을 추적합니다.

```
> /omb:run
# 계획 읽기 → 태스크별 에이전트 생성 → RED-GREEN-IMPROVE 사이클 → 완료 표시
# 진행상황: .omb/todo/
```

#### `/omb:verify` — 구현 후 검증

병렬 검증자(타입 체크, lint, 테스트, 도메인별 에이전트)를 조립하고, 정적 분석을 실행하며, DONE/RETRY/BLOCKED 판정을 내립니다.

```
> /omb:verify
# tsc, ruff, pytest, eslint 실행 → 도메인 에이전트 리뷰 → 합의 판정
```

#### `/omb:doc` — 문서화

카테고리 구조와 명명 규칙에 따라 서비스 문서를 생성하거나 업데이트합니다.

```
> /omb:doc
# 변경 사항 스캔 → docs/ 폴더에 문서 생성 → 템플릿 규칙 적용
```

#### `/omb:pr` — Pull Request

브랜치 검증, lint 체크 실행, 커밋 생성, 푸시, 구조화된 템플릿으로 GitHub PR을 생성합니다.

```
> /omb:pr
# lint 게이트 → 커밋 → 푸시 → 요약/변경사항/테스트 계획이 포함된 PR 생성
```

#### `/omb:release` — 릴리즈

버전 범프, AI 요약 변경 로그, git 태깅, GitHub Release 생성, CI 트리거 바이너리 빌드를 처리합니다.

```
> /omb:release patch
> /omb:release minor
> /omb:release 2.0.0
```

#### `/omb:harness` — 하네스 설정

에이전트, 스킬, hooks, rules, settings.json을 생성, 업데이트, 검증, 설계합니다.

```
> /omb:harness --verify    # 설정 상태 검사
> /omb:harness --fix       # 이슈 자동 수정
```

### 유틸리티

#### `/omb:setup` — 프로젝트 설정

디렉토리 구조 생성, `CLAUDE.md` 생성, `settings.json`에 hooks 및 환경 변수를 설정합니다.

```
> /omb:setup
# 대화형 마법사: 코드베이스 스캔 → CLAUDE.md 생성 → hooks 설정
```

#### `/omb:lint-check` — Lint 검사

변경된 파일에서 기술 스택을 자동 감지하고 적절한 린터를 실행합니다. PR 전에 반드시 통과해야 합니다.

```
> /omb:lint-check
# Python 감지 → ruff, TypeScript → eslint, Dockerfile → hadolint
```

#### `/omb:prompt-guide` — 프롬프트 엔지니어링 가이드

시스템 프롬프트, 에이전트 지시문, 스킬 설명 작성을 위한 종합 프롬프트 엔지니어링 가이드(11개 카테고리, 52개 규칙)를 로드합니다.

```
> /omb:prompt-guide
```

#### `/omb:prompt-review` — 프롬프트 리뷰

반복적 프롬프트 채점 및 개선 루프. 루브릭에 대해 평가하고, P0/P1 이슈를 수정하며, 해결될 때까지 재평가합니다.

```
> /omb:prompt-review
# 프롬프트 채점 → 이슈 식별 → 수정 → 통과할 때까지 재채점
```

#### `/omb:brainstorming` — 아이디어 탐색

의도, 제약 조건, 접근 방식을 정제하기 위해 한 번에 하나씩 질문하는 협업 대화입니다.

```
> /omb:brainstorming
# 설계에 착수하기 전 아이디어를 탐색하는 대화형 Q&A
```

#### `/omb:mermaid` — 다이어그램 생성

플로차트, 시퀀스 다이어그램, ER 다이어그램, LangGraph 시각화 등 22가지 유형의 Mermaid 다이어그램을 생성합니다.

```
> /omb:mermaid
# 컨텍스트 분석 → 다이어그램 유형 선택 → 검증된 Mermaid 구문 생성
```

#### `/omb:worktree` — Worktree 관리

SQLite 상태 추적을 통해 격리된 git worktree를 관리합니다.

```
> /omb:worktree create feat/add-auth   # 격리된 worktree 생성
> /omb:worktree status                 # 모든 worktree 상태 조회
> /omb:worktree resume feat/add-auth   # 기존 worktree로 전환
```

#### `/omb:clean` — Worktree 정리

완료된 worktree를 제거하고 DB에 DONE으로 표시하며, 선택적으로 브랜치를 삭제합니다.

```
> /omb:clean feat/add-auth             # worktree 제거 및 완료 표시
```

#### `/omb:issue` — 이슈 스캐너

코드베이스에서 이슈를 스캔하고, 병렬 탐색 에이전트를 파견하며, 구조화된 템플릿으로 GitHub 이슈를 생성합니다.

```
> /omb:issue
# 체크리스트 구성 → 병렬 스캔 → 합의 도출 → gh issue create
```

#### `/omb:git-setup` — Git 워크플로우 설정

pre-commit hooks(ruff, eslint)를 설정하고, `.gitignore`를 검토하며, GitHub Actions CI를 구성합니다.

```
> /omb:git-setup
# pre-commit hooks 설치 → .gitignore 검토 → CI 워크플로우 생성
```

### Codex 연동

[OpenAI Codex CLI](https://github.com/openai/codex)와 연동하여 코드 리뷰 및 태스크 위임을 수행합니다.

#### `/omb:codex` — Codex 디스패처

적절한 Codex 하위 명령어로 라우팅합니다.

```
> /omb:codex review       # 코드 리뷰
> /omb:codex adv-review   # 적대적 리뷰
> /omb:codex run           # 태스크 위임
> /omb:codex setup         # 설치 확인
```

#### `/omb:codex-review` — 코드 리뷰

로컬 git 상태에서 Codex 코드 리뷰를 실행하고 결과를 보고합니다.

```
> /omb:codex-review
# staged/unstaged 변경 사항 분석 → 이슈 및 제안 보고
```

#### `/omb:codex-adv-review` — 적대적 리뷰

가정에 도전하고, 실패 모드를 찾으며, 구현 선택을 압박 테스트합니다.

```
> /omb:codex-adv-review
# 심층 분석: 엣지 케이스, 실패 모드, 보안 문제, 확장성
```

#### `/omb:codex-run` — 태스크 위임

조사, 버그 수정, 구현을 위해 Codex CLI에 코딩 태스크를 위임합니다.

```
> /omb:codex-run fix the flaky test in tests/test_auth.py
> /omb:codex-run add input validation to the /api/users endpoint
```

#### `/omb:codex-setup` — 설치 확인

Codex CLI 설치 상태, 인증 상태를 확인하고 연결 테스트를 실행합니다.

```
> /omb:codex-setup
# 확인: codex 바이너리 → 인증 상태 → 연결 테스트
```

## oh-my-braincrew란?

Claude Code를 확장하는 멀티 에이전트 오케스트레이션 하네스:

- **20+ 전문 에이전트** — 10개 도메인에서 설계, 구현, 검증, 리뷰
- **구조화된 워크플로우** — 계획 → 리뷰 → 실행 (TDD) → 검증 → 문서화 → PR
- **품질 게이트** — 자동화된 lint, 타입 체크, 테스트 검증
- **도메인 라우팅** — API, DB, UI, AI/ML, Infra, Security, Electron, Harness
- **Worktree 격리** — SQLite 상태 추적을 통한 병렬 기능 개발

## 변경 로그

릴리즈 히스토리는 [CHANGELOG.md](./CHANGELOG.md)를 참고하세요.

## 라이선스

Apache-2.0
