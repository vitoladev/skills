---
name: get-pr-comments
description: |
  Summarise review threads and discussion comments on the current branch's
  pull request. Use when invoked as /get-pr-comments, when asked to fetch or
  summarise PR comments, review feedback, or GitHub review threads, or before
  deciding whether a review comment is worth fixing.
---

# Get PR comments

Concise, actionable summary of feedback on **this branch's** PR. Do not fix
anything unless asked. `gh` runs on the host, never inside the repo's command
boundary. Do not use GitHub MCP as the primary fetch path.

## 1. Resolve this branch's PR

Stacked work: the current branch owns one PR. Do not summarise the stack top
unless that is the checked-out branch.

```bash
gh stack view --json 2>/dev/null   # empty/error when this is not a stack
git branch --show-current
```

Match the current branch to its `pr.number`. If the branch is not in a stack:

```bash
gh pr view --json number,url,title
```

Need `owner`/`name` for later calls: `gh repo view --json nameWithOwner`.

## 2. Fetch threads and discussion

Review **threads** (needed later to reply/resolve) via GraphQL. Paginate while
`hasNextPage`.

```bash
gh api graphql -f query='
query($owner:String!, $name:String!, $number:Int!) {
  repository(owner:$owner, name:$name) {
    pullRequest(number:$number) {
      reviewThreads(first:100) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first:50) {
            nodes {
              databaseId
              author { login }
              body
              createdAt
              url
            }
          }
        }
      }
    }
  }
}' -F owner=<owner> -F name=<repo> -F number=<n>
```

Discussion (not resolvable as a review thread):

```bash
gh api repos/<owner>/<repo>/issues/<n>/comments
gh api repos/<owner>/<repo>/pulls/<n>/reviews
```

`gh api repos/.../pulls/<n>/comments` is the REST view of the same inline
comments; prefer GraphQL so each group has a thread `id` (`PRRT_…`).

## 3. Group feedback

Skip noise: resolved + outdated with no new reply, bot boilerplate, and
threads the user already handled in this conversation.

Use the repo's own domain vocabulary — its glossary when it has one, its
schema and type names otherwise. Do not drift to synonyms the codebase avoids.

Group remaining items:

| Group | Meaning |
|---|---|
| Must fix | Bug, broken invariant, or contract lie |
| Consider | Design, missing test, or race that may already be closed |
| Nit | Style, naming, optional cleanup |
| Question | Needs a human answer before code moves |

For each item include: path + line, author, unresolved/resolved, the GraphQL
thread `id`, and the latest comment's REST `databaseId` (needed by
`/resolve-pr-comment`).

Do not treat a review comment as a task until it is true against the current
code. Say so when it is already fixed, outdated, or based on a wrong model.

## 4. Output

- Grouped summary (unresolved first)
- Action list ordered by priority — empty if nothing to do
- Open questions that still need a human

Done when the user can decide what to fix, reply to, or ignore without opening
GitHub.
