# 使用 git subtree（本地使用指南）

本文档说明如何在本地将外部仓库以 subtree 方式添加到项目、拉取更新以及把对子目录的修改推送回子仓库。

## 一、基本使用流程（核心命令）

1) 添加一个 subtree

```
git subtree add --prefix=lib https://github.com/example/lib.git main --squash
```

说明：
- `--prefix=lib`：把代码放到 `lib/` 目录
- `repo URL`：外部仓库地址
- `main`：分支名（根据子仓库实际分支调整）
- `--squash`：压缩历史，强烈推荐（把子仓库的历史合并为一次提交）

执行后效果：
- 你的仓库下会出现 `lib/`（其中包含完整代码）
- clone 后无需任何额外操作，直接可用

---

2) 更新 subtree（拉取新版本）

```
git subtree pull --prefix=lib https://github.com/example/lib.git main --squash
```

类似于对 `lib/` 目录做一次 `git pull`，但作用范围仅限于该目录。

---

3) 推送修改回子仓库（如果你修改了 `lib`）

```
git subtree push --prefix=lib https://github.com/example/lib.git main
```

场景：
- 你在 `lib/` 下做了修改并希望同步回原仓库

---

## 二、推荐最佳实践（非常重要）

- 一定使用 `--squash`：
  - 否则会把整个子仓库的历史带进来，导致仓库历史体积膨胀且 `git log` 难看

- 建议为子仓库添加一个 remote（更好管理）

示例：

```
git remote add lib-repo https://github.com/example/lib.git

# 然后可以用 remote 名称：
git subtree add --prefix=lib lib-repo main --squash
git subtree pull --prefix=lib lib-repo main --squash
```

添加 remote 的好处：方便管理 URL、切换分支或改用其他仓库地址。

---

## 三、补充说明

- 如果你希望频繁与子仓库双向同步，请确保对 pull/push 的流程和权限（例如有推送权限）有清楚的约定。
- `subtree` 适用于把外部代码作为子目录直接集成到主仓库的场景，操作相对简单且不需要子模块的额外维护。
