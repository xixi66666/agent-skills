# agent-skills

这个仓库用于在多台电脑之间同步 Codex 的全局 skills 和共享 MCP 配置。

当前策略是全量快照：仓库里的 `skills/` 就是全局 skills 的源。每台电脑 clone 后运行安装脚本，脚本会把这些 skills 同步到当前用户目录下的 `~/.agents/skills`，不会写死 Windows 用户名。

## 目录结构

```text
skills/                 全局 skills 快照，会同步到 ~/.agents/skills
mcp/shared.toml         共享 [mcp_servers.*] 配置
scripts/install.ps1     将本仓库应用到当前电脑
scripts/sync.ps1        先 git pull，再应用到当前电脑
scripts/export-local.ps1
                        将当前电脑的 ~/.agents/skills 回写到本仓库
```

## 新电脑首次安装

先把仓库 clone 到任意你喜欢的位置：

```powershell
git clone https://github.com/xixi66666/agent-skills.git
cd agent-skills
```

然后执行安装：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

安装完成后重启 Codex，让新的全局 skills 和 MCP 配置被重新读取。

## 已有 skills 或 MCP 的电脑首次接入

如果另一台电脑已经安装过部分 skills 或 MCP，可以直接接入，但第一次建议使用默认安装，不要使用 `-MirrorSkills`。

推荐流程：

```powershell
git clone https://github.com/xixi66666/agent-skills.git
cd agent-skills
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

默认安装会做这些事：

```text
1. 将仓库里的 skills 复制到当前电脑的 ~/.agents/skills
2. 不删除当前电脑已有但仓库里没有的 skills
3. 备份当前电脑的 ~/.codex/config.toml
4. 只替换与 mcp/shared.toml 同名的 [mcp_servers.*] 配置段
5. 保留模型设置、项目 trust、插件配置、登录态、sessions、cache、sqlite 状态
```

第一次接入时不要运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -MirrorSkills
```

`-MirrorSkills` 会让 `~/.agents/skills` 与仓库完全一致，包括删除仓库里不存在的本机 skills。它适合电脑已经统一之后做强制收敛，不适合第一次合并。

## 合并另一台电脑独有的 skills

如果另一台电脑上有想保留并纳入统一仓库的 skills，先按默认方式安装仓库内容，再把最终的本机全局 skills 回写到仓库：

```powershell
git clone https://github.com/xixi66666/agent-skills.git
cd agent-skills
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\export-local.ps1
git status
git add .
git commit -m "Merge skills from another host"
git push
```

然后其他电脑运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync.ps1
```

这样可以把那台电脑独有的 skills 也纳入统一快照。

## 合并另一台电脑独有的 MCP

MCP 不建议自动从其他电脑导出到仓库，因为 MCP 配置里可能包含本机路径、私有服务地址、环境变量名或敏感配置。

如果另一台电脑有需要共享的 MCP，请手动打开那台电脑的：

```text
~/.codex/config.toml
```

找到对应的：

```toml
[mcp_servers.xxx]
```

确认不包含真实 token、密码、私钥或只适用于单台电脑的绝对路径后，再复制到本仓库的：

```text
mcp/shared.toml
```

如果必须写本机路径，使用占位符：

```toml
args = ["{{USERPROFILE}}\\some\\tool"]
```

改完后提交推送：

```powershell
git add mcp/shared.toml
git commit -m "Merge MCP config from another host"
git push
```

其他电脑再运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync.ps1
```

## 日常同步

其他电脑上有更新后，在本机运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync.ps1
```

这个命令会先执行 `git pull --ff-only`，再把仓库内容同步到当前电脑。

如果你只想应用本地仓库内容，不想联网拉取：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync.ps1 -NoPull
```

## 严格镜像 skills

默认安装会把仓库里的 skills 复制到 `~/.agents/skills`，但不会删除目标目录里额外存在的 skill。

如果你想让当前电脑的全局 skills 和仓库完全一致，包括删除仓库里不存在的旧 skill，使用：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -MirrorSkills
```

或：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync.ps1 -MirrorSkills
```

## 在一台电脑上新增或修改 skills

以后安装 GitHub 上的 skill，推荐使用本仓库提供的全局安装脚本。它会自动把安装目标设置为当前用户的 `~/.agents/skills`，避免误装到 `~/.codex/skills`。

使用 `owner/repo + path` 安装：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-github-skill-global.ps1 `
  -Repo owner/repo `
  -Path path/to/skill
```

使用 GitHub URL 安装：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-github-skill-global.ps1 `
  -Url https://github.com/owner/repo/tree/main/path/to/skill
```

一次安装多个 skill：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-github-skill-global.ps1 `
  -Repo owner/repo `
  -Path path/to/skill-a,path/to/skill-b
```

安装后立即回写到本仓库：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-github-skill-global.ps1 `
  -Repo owner/repo `
  -Path path/to/skill `
  -ExportLocal
```

然后提交并推送：

```powershell
git status
git add .
git commit -m "Add global skill"
git push
```

脚本也支持这些可选参数：

```text
-Ref <branch-or-tag>       指定 Git ref，默认 main
-Name <skill-name>         单个 skill 安装时指定目标目录名
-Method auto|download|git  指定安装方式，默认 auto
-ExportLocal               安装成功后运行 export-local.ps1 -SkipMcp
```

如果是手动编辑本机的全局 skills，确认无误后，把当前电脑的全局 skills 回写到仓库：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-local.ps1
```

然后提交并推送：

```powershell
git status
git add .
git commit -m "Update global skills"
git push
```

其他电脑再运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync.ps1
```

同步完成后重启 Codex，让新加入或更新后的 skills 被重新扫描。

### 其他主机更新到新增 skill

当本仓库新增了 skill（例如 `vercel-deploy`）后，其他主机只需要进入各自 clone 的 `agent-skills` 仓库并运行：

```powershell
git pull --ff-only
powershell -ExecutionPolicy Bypass -File .\scripts\sync.ps1 -NoPull
```

也可以直接运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync.ps1
```

`sync.ps1` 会先拉取远端，再把仓库里的 `skills/` 同步到当前用户的 `~/.agents/skills`。同步完成后重启 Codex。

## 只同步其中一部分

只同步 skills，不改 MCP：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -SkipMcp
```

只同步 MCP，不改 skills：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -SkipSkills
```

`sync.ps1` 也支持同样参数：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync.ps1 -SkipMcp
powershell -ExecutionPolicy Bypass -File .\scripts\sync.ps1 -SkipSkills
```

## MCP 同步规则

`scripts/install.ps1` 会备份当前电脑的 `~/.codex/config.toml`，然后移除与 `mcp/shared.toml` 同名的 `[mcp_servers.*]` 配置段，并追加一个由本仓库管理的 MCP 配置块。

它不会覆盖这些本机状态：

```text
模型设置
项目 trust 设置
插件开关
登录态 auth.json
sessions
cache
sqlite 状态文件
```

如果 MCP 配置里需要写本机路径，不要写死用户名。使用占位符：

```toml
args = ["{{USERPROFILE}}\\some\\tool"]
```

安装脚本会在当前电脑上展开 `{{USERPROFILE}}` 和 `{{HOME}}`。

## 备份位置

安装脚本每次运行前会备份已有目录或配置。备份文件放在：

```text
.backup/
```

这个目录已被 `.gitignore` 忽略，不会提交到仓库。

## 当前包含的第三方 skills

本仓库已经包含 `mattpocock/skills` 中的以下 skills：

```text
caveman
diagnose
git-guardrails-claude-code
grill-me
grill-with-docs
improve-codebase-architecture
migrate-to-shoehorn
prototype
scaffold-exercises
setup-matt-pocock-skills
setup-pre-commit
tdd
to-issues
to-prd
triage
write-a-skill
zoom-out
```

本仓库也包含 `obra/superpowers` 5.1.0 中的以下 skills：

```text
brainstorming
dispatching-parallel-agents
executing-plans
finishing-a-development-branch
receiving-code-review
requesting-code-review
subagent-driven-development
systematic-debugging
test-driven-development
using-git-worktrees
using-superpowers
verification-before-completion
writing-plans
writing-skills
```

本仓库还包含 OpenAI curated skills 中的：

```text
vercel-deploy
```

`vercel-deploy` 用于把网站或应用部署到 Vercel。默认应创建 preview deployment；只有用户明确要求生产发布时，才使用 production deploy。

本仓库还包含 `pbakaus/impeccable` 中的：

```text
impeccable
```

`impeccable` 用于设计、审查和改进前端界面，包含设计上下文初始化、UX/UI 评审、无障碍与响应式审计、视觉润色、动效、排版、布局及浏览器迭代等工作流。在 Codex 中使用 `$impeccable`，新项目前端设计建议先运行：

```text
$impeccable init
```

常用示例：

```text
$impeccable audit
$impeccable critique landing
$impeccable polish settings
```

本仓库同步的是用户级 `impeccable` skill。Impeccable 的 Codex 检测 Hook 属于项目级配置，不会随用户级 skill 自动安装；需要 Hook 时，在目标前端项目中按上游文档执行 `npx impeccable install --providers=codex --scope=project`，然后在 Codex 中打开 `/hooks` 并批准该项目 Hook。

## 常见问题

如果 PowerShell 阻止脚本运行，使用 README 里的 `-ExecutionPolicy Bypass` 命令即可。

如果 Git 提示 unsafe repository，可以把仓库加入安全目录：

```powershell
git config --global --add safe.directory "<你的 agent-skills 仓库绝对路径>"
```

如果同步后 Codex 没看到新 skills，重启 Codex。
