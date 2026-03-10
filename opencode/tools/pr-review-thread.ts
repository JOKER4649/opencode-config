import { tool } from "@opencode-ai/plugin"

// Intent: 补充 GitHub CLI 缺少的 PR review thread 操作 (resolve/unresolve)
// Caveats: 依赖 `gh` CLI 已认证; GraphQL node_id 由 list 工具提供

/**
 * 列出 PR 的所有 review threads (含 node_id, 状态, 首条评论)
 */
export const list = tool({
  description:
    "List all review threads for a GitHub pull request. Returns thread IDs, resolved status, and first comment. Use this to get thread IDs before calling resolve.",
  args: {
    owner: tool.schema.string().describe("Repository owner"),
    repo: tool.schema.string().describe("Repository name"),
    pr_number: tool.schema.number().describe("Pull request number"),
  },
  async execute(args) {
    const query = `
      query($owner: String!, $repo: String!, $number: Int!) {
        repository(owner: $owner, name: $repo) {
          pullRequest(number: $number) {
            reviewThreads(first: 100) {
              nodes {
                id
                isResolved
                isOutdated
                path
                line
                comments(first: 3) {
                  nodes {
                    author { login }
                    body
                  }
                }
              }
            }
          }
        }
      }
    `
    const result =
      await Bun.$`gh api graphql -f query=${query} -F owner=${args.owner} -F repo=${args.repo} -F number=${args.pr_number}`
        .text()
        .catch((e) => {
          throw new Error(`gh api graphql failed: ${e.message}`)
        })

    const data = JSON.parse(result)
    const threads =
      data?.data?.repository?.pullRequest?.reviewThreads?.nodes ?? []

    // Reason: 简化输出, 只保留 agent 决策所需的字段
    const summary = threads.map(
      (t: {
        id: string
        isResolved: boolean
        isOutdated: boolean
        path: string | null
        line: number | null
        comments: {
          nodes: Array<{ author: { login: string }; body: string }>
        }
      }) => ({
        thread_id: t.id,
        resolved: t.isResolved,
        outdated: t.isOutdated,
        path: t.path,
        line: t.line,
        first_comments: t.comments.nodes.map((c) => ({
          author: c.author.login,
          body:
            c.body.length > 200 ? c.body.substring(0, 200) + "..." : c.body,
        })),
      }),
    )

    return JSON.stringify(summary, null, 2)
  },
})

/**
 * 解决 (resolve) 一个 PR review thread
 */
export const resolve = tool({
  description:
    "Resolve a GitHub PR review thread by its thread ID (GraphQL node ID). Get thread IDs from the list tool first.",
  args: {
    thread_id: tool.schema
      .string()
      .describe("GraphQL node ID of the review thread (from list tool)"),
  },
  async execute(args) {
    const mutation = `
      mutation($threadId: ID!) {
        resolveReviewThread(input: { threadId: $threadId }) {
          thread {
            id
            isResolved
          }
        }
      }
    `
    const result =
      await Bun.$`gh api graphql -f query=${mutation} -F threadId=${args.thread_id}`
        .text()
        .catch((e) => {
          throw new Error(`gh api graphql failed: ${e.message}`)
        })

    const data = JSON.parse(result)
    if (data.errors) {
      throw new Error(
        `GraphQL errors: ${data.errors.map((e: { message: string }) => e.message).join(", ")}`,
      )
    }

    const thread = data?.data?.resolveReviewThread?.thread
    return thread?.isResolved
      ? `Thread ${thread.id} resolved successfully.`
      : `Unexpected state: thread may not be resolved. Response: ${JSON.stringify(data)}`
  },
})

/**
 * 取消解决 (unresolve) 一个 PR review thread
 */
export const unresolve = tool({
  description:
    "Unresolve a GitHub PR review thread by its thread ID (GraphQL node ID).",
  args: {
    thread_id: tool.schema
      .string()
      .describe("GraphQL node ID of the review thread"),
  },
  async execute(args) {
    const mutation = `
      mutation($threadId: ID!) {
        unresolveReviewThread(input: { threadId: $threadId }) {
          thread {
            id
            isResolved
          }
        }
      }
    `
    const result =
      await Bun.$`gh api graphql -f query=${mutation} -F threadId=${args.thread_id}`
        .text()
        .catch((e) => {
          throw new Error(`gh api graphql failed: ${e.message}`)
        })

    const data = JSON.parse(result)
    if (data.errors) {
      throw new Error(
        `GraphQL errors: ${data.errors.map((e: { message: string }) => e.message).join(", ")}`,
      )
    }

    const thread = data?.data?.unresolveReviewThread?.thread
    return !thread?.isResolved
      ? `Thread ${thread.id} unresolved successfully.`
      : `Unexpected state: thread may still be resolved. Response: ${JSON.stringify(data)}`
  },
})
