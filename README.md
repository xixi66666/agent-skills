# codex-global-config

Global Codex skills and shared MCP configuration for multiple hosts.

This repository is designed to be cloned on each machine. It avoids fixed user
names by resolving paths from `$env:USERPROFILE`.

## Layout

```text
skills/              Global skills copied to ~/.agents/skills
mcp/shared.toml      Shared [mcp_servers.*] config
scripts/install.ps1  Apply this repo to the current host
scripts/sync.ps1     Pull from Git if a remote exists, then install
scripts/export-local.ps1
                     Copy current ~/.agents/skills back into this repo
```

## First install on a host

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

Use `-MirrorSkills` if you want the target skill directory to exactly match this
repo, including deleting skills that are no longer present here.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -MirrorSkills
```

## Regular sync

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync.ps1
```

If the repo has a remote, this runs `git pull --ff-only` first. If no remote is
configured yet, it just applies the local repository state.

## Export local skill changes

After adding or editing skills on one host:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-local.ps1
git add .
git commit -m "Update Codex global skills"
git push
```

Then run `scripts\sync.ps1` on the other hosts.

## MCP behavior

`scripts/install.ps1` backs up `~/.codex/config.toml`, removes existing
`[mcp_servers.*]` sections with the same names as `mcp/shared.toml`, and appends
a managed MCP block.

It does not overwrite model settings, project trust settings, plugin settings,
sessions, auth files, caches, or sqlite state.

For host-specific MCP paths, put placeholders in `mcp/shared.toml`:

```toml
args = ["{{USERPROFILE}}\\some\\tool"]
```

The install script expands `{{USERPROFILE}}` and `{{HOME}}` for the current
machine.
