# dotfiles

模块化 Bash 配置仓库，通过软链接管理 `~/.bashrc`。

## 结构

```
dotfiles/
├── bash/
│   ├── bashrc          # 主入口（被 ~/.bashrc 软链接指向）
│   ├── 00-core         # Shell 默认行为（历史、提示符、补全）
│   ├── 10-env          # 环境变量与 PATH（去重 helper）
│   ├── 20-aliases      # 别名（修复了 kj 冲突）
│   ├── 30-functions    # 自定义函数（proxy、CUDA、docker-clean 等）
│   ├── 40-tools        # 第三方工具初始化（conda、fzf、starship、zoxide）
│   ├── secrets         # API 密钥（gitignored，手动创建）
│   └── secrets.example # 密钥模板
├── bin/
│   └── claude-switch   # Claude Code settings provider 切换工具
├── install.sh          # 一键安装脚本
└── .gitignore
```

## 安装

```bash
cd /media/yhr/2T/files/cc_projects/dotfiles
./install.sh
```

然后复制密钥模板并填入真实值：

```bash
cp bash/secrets.example bash/secrets
# 编辑 bash/secrets，取消注释并填入你的 token
```

## 修改后重载

```bash
src   # alias，等同于 source ~/.bashrc
```

## Claude Code 配置切换

`claude-switch` 用于在本机的 Claude Code 配置之间切换。它会从
`~/.claude/settings_*.json` 读取 profile，也可以直接从 `bash/secrets`
读取内置 profile 变量，并写入 `~/.claude/settings.json`。切换后需要重启
Claude Code 才会生效。

常用命令：

```bash
claude-switch list
claude-switch current
claude-switch kimi
claude-switch deepseek
claude-switch
```

本地 profile 示例：

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "sk-xxxx",
    "ANTHROPIC_BASE_URL": "https://your-anthropic-compatible-endpoint",
    "ANTHROPIC_MODEL": "your-model-name"
  }
}
```

官方 Anthropic API 通常使用 `ANTHROPIC_API_KEY`。Kimi、DeepSeek 或其他
Anthropic-compatible 代理需要映射到 Claude Code 标准变量：
`ANTHROPIC_AUTH_TOKEN`、`ANTHROPIC_BASE_URL`、`ANTHROPIC_MODEL` 以及相关
default model 变量。

把真实配置保存在 `~/.claude/settings_kimi.json`、
`~/.claude/settings_deepseek.json` 等本机文件里，不要提交到仓库。
如果使用 `bash/secrets` 管理变量，则配置如下：

```bash
export KIMI_API_KEY="sk-xxxxxxxx"
export KIMI_ANTHROPIC_BASE_URL="https://your-kimi-anthropic-endpoint"
export KIMI_ANTHROPIC_MODEL="your-kimi-model"

export DEEPSEEK_API_KEY="sk-xxxxxxxx"
export DEEPSEEK_ANTHROPIC_BASE_URL="https://your-deepseek-anthropic-endpoint"
export DEEPSEEK_ANTHROPIC_MODEL="your-deepseek-model"
export DEEPSEEK_ANTHROPIC_DEFAULT_OPUS_MODEL="your-deepseek-opus-model"
export DEEPSEEK_ANTHROPIC_DEFAULT_SONNET_MODEL="your-deepseek-sonnet-model"
export DEEPSEEK_ANTHROPIC_DEFAULT_HAIKU_MODEL="your-deepseek-haiku-model"
export DEEPSEEK_CLAUDE_CODE_SUBAGENT_MODEL="your-deepseek-haiku-model"
export DEEPSEEK_CLAUDE_CODE_EFFORT_LEVEL="max"
```

## 已修复的问题

- ✅ `kj` 别名冲突：原复杂 kill 逻辑保留为 `kjsoft`，`kj` 简化为 `kill -9 %%`
- ✅ PATH 重复：`cmake` 去重，使用 `add_path()` helper
- ✅ 密钥硬编码：全部迁移到 `bash/secrets`（已加入 `.gitignore`）
- ✅ CUDA 切换：`ln -s` 改为 `ln -sfn` 原子替换
