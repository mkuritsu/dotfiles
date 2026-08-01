# Global Agent Guidelines

## GitHub and GitLab

- Prefer using the GitHub and GitLab CLIs over web search when interacting with GitHub or GitLab.
- Never perform mutating or write operations with those CLIs unless explicitly asked to do so. This includes creating or deleting repositories, opening or modifying pull requests, approving pull requests, and similar operations.

## General Programming Guidelines

- Never edit lockfiles manually unless explicitly asked to do so.
- When installing dependencies, always use the respective package manager's commands (for example, `cargo`, `npm`, `pnpm`, or `bun`).

## TypeScript Guidelines

- Never use `any`; always prefer a typed approach. When a type cannot be expressed safely, use `unknown`.
- Avoid explicit return types. Prefer to let TypeScript infer them unless explicitly asked, or when writing a contract/interface for a component.
- Always use the package manager currently used by the project (`npm`, `pnpm`, `bun`, etc.).
- Above all, ensure type safety. Make the types provide the desired safety and avoid redundant runtime verification when the type system has already performed that verification.
- When an "Error as values" library is present in the codebase (for example, Better Result, Effect TS, or another equivalent), always use it instead of plain `try`/`catch`.
