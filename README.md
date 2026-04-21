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

## 已修复的问题

- ✅ `kj` 别名冲突：原复杂 kill 逻辑保留为 `kjsoft`，`kj` 简化为 `kill -9 %%`
- ✅ PATH 重复：`cmake` 去重，使用 `add_path()` helper
- ✅ 密钥硬编码：全部迁移到 `bash/secrets`（已加入 `.gitignore`）
- ✅ CUDA 切换：`ln -s` 改为 `ln -sfn` 原子替换
