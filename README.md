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

先正常安装或编辑本机的全局 skills。确认无误后，把当前电脑的全局 skills 回写到仓库：

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

## 常见问题

如果 PowerShell 阻止脚本运行，使用 README 里的 `-ExecutionPolicy Bypass` 命令即可。

如果 Git 提示 unsafe repository，可以把仓库加入安全目录：

```powershell
git config --global --add safe.directory "<你的 agent-skills 仓库绝对路径>"
```

如果同步后 Codex 没看到新 skills，重启 Codex。
