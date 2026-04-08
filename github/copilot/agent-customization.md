# 📘 Copilot Agent Customization 全景架构说明

***

# 🧠 一、整体架构（先建立正确心智模型）

VS Code Copilot Agent Customization 体系本质上是：

> 一套可编排的 AI 执行系统（Agentic Runtime）

官方 Handbook 明确指出：

GitHub Copilot 提供多个 **Customization Mechanisms**，每个机制用于解决不同问题，组合使用可以构建一致的 AI 工作流。 [\[copilot-ac....github.io\]](https://copilot-academy.github.io/workshops/copilot-customization/copilot_customization_handbook)

***

## 🏗️ Agent Runtime 结构（推荐记住这个）

    Copilot Agent Runtime
    │
    ├─ Instructions    → 行为规则
    ├─ Agents         → 执行角色
    ├─ Skills         → 能力模块
    ├─ Prompts        → 任务模板
    ├─ Hooks          → 执行拦截器
    ├─ MCP Servers    → 外部系统连接
    └─ Plugins        → 分发打包机制

***

# 🟦 二、Instructions（行为规则层）

***

## ✅ 定义

Instructions 是：

👉 自动加载的行为规范文件

官方说明：

> Instructions define the always‑on project context automatically included in every chat interaction [\[copilot-ac....github.io\]](https://copilot-academy.github.io/workshops/copilot-customization/copilot_customization_handbook)

***

## ✅ 作用

用于定义：

*   Coding Standard
*   Naming Convention
*   Infra Guardrail
*   Security Policy

***

## ✅ 运行方式

    Always-On
    自动注入 System Prompt

***

## ✅ 示例（AKS Landing Zone）

```markdown
Always deploy AKS as private cluster
Enable Azure Monitor
Use RBAC enabled
```

***

👉 Instruction = Azure Policy

***

# 🟪 三、Agents（角色层）

***

## ✅ 定义

Agent 是：

👉 AI Persona（角色）

官方：

> Custom Agents are named personas with specific tools and rules [\[dev.to\]](https://dev.to/pwd9000/github-copilot-instructions-vs-prompts-vs-custom-agents-vs-skills-vs-x-vs-why-339l)

***

## ✅ 作用

定义：

*   谁在干活
*   能用什么工具
*   能不能执行 terminal
*   能不能写文件

***

## ✅ 示例

| Agent           | 角色     |
| --------------- | ------ |
| Plan Agent      | 架构师    |
| Implement Agent | DevOps |
| Review Agent    | SRE    |

***

👉 Agent = Pipeline Role

***

# 🟨 四、Skills（能力层）

***

## ✅ 定义

Skill 是：

👉 可复用能力包（脚本 + 指令）

官方：

> Agent Skills are portable specialized capabilities with resources [\[copilot-ac....github.io\]](https://copilot-academy.github.io/workshops/copilot-customization/copilot_customization_handbook)

***

## ✅ 作用

定义：

    how-to
    执行流程
    Runbook

***

## ✅ 示例（AKS）

deploy‑aks Skill：

    terraform init
    terraform plan
    terraform apply

***

👉 Skill = Terraform Module

***

# 🟧 五、Prompts（任务模板层）

***

## ✅ 定义

Prompt File 是：

👉 手动触发的任务模板

官方：

> Prompt files are reusable task templates invoked on-demand [\[copilot-ac....github.io\]](https://copilot-academy.github.io/workshops/copilot-customization/copilot_customization_handbook)

***

## ✅ 作用

用于：

*   代码审查
*   Terraform部署
*   PR生成
*   单次流程任务

***

## ✅ 使用方式

    /deploy-aks
    /code-review
    /create-module

***

👉 Prompt = Runbook

***

# 🟥 六、Hooks（执行控制层）

***

## ✅ 定义

Hook 是：

👉 在 Agent 生命周期节点运行的脚本

官方：

> Hooks execute custom shell commands at key lifecycle points during agent sessions [\[code.visua...studio.com\]](https://code.visualstudio.com/docs/copilot/customization/hooks)

***

## ✅ 作用

Hooks 可以：

✅ Block  
✅ Modify  
✅ Approve  
✅ Audit  
✅ Automate

***

## ✅ 生命周期触发点

例如：

| Event        | 作用    |
| ------------ | ----- |
| PreToolUse   | 执行前拦截 |
| PostToolUse  | 执行后处理 |
| SessionStart | 初始化   |
| Stop         | 会话结束  |

***

## ✅ 示例（AKS）

阻止：

    terraform destroy
    az group delete

***

👉 Hook = Policy Enforcement Engine

***

# 🟩 七、MCP Servers（系统连接层）

***

## ✅ 定义

MCP Server 是：

👉 外部 Tool Provider

官方：

> MCP servers provide tools for external APIs and systems [\[copilot-ac....github.io\]](https://copilot-academy.github.io/workshops/copilot-customization/copilot_customization_handbook)

***

## ✅ 作用

Agent 可通过 MCP：

*   查询 AKS
*   Assign RBAC
*   创建 NSG
*   读取 Log Analytics
*   调用 Azure API

***

## ✅ 架构

    Agent
      ↓
    MCP Client
      ↓
    MCP Server
      ↓
    Azure / K8s API

***

👉 MCP = Service Connection

***

# 🟫 八、Plugins（分发层）

***

## ✅ 定义

Plugin 是：

👉 Customization Bundle

官方：

> Agent plugins are prepackaged bundles of chat customizations [\[code.visua...studio.com\]](https://code.visualstudio.com/docs/copilot/customization/agent-plugins)

***

## ✅ Plugin 可以包含：

*   Slash Commands
*   Skills
*   Agents
*   Hooks
*   MCP Servers

***

官方说明：

> A single plugin can provide any combination of slash commands, agent skills, custom agents, hooks, and MCP servers [\[code.visua...studio.com\]](https://code.visualstudio.com/docs/copilot/customization/agent-plugins)

***

👉 Plugin = Package Manager

***

# 🧩 九、完整 DevOps 类比

***

| Copilot层     | DevOps类比           |
| ------------ | ------------------ |
| Instructions | Azure Policy       |
| Agent        | Pipeline Role      |
| Skill        | Terraform Module   |
| Prompt       | Runbook            |
| Hook         | OPA / Policy Gate  |
| MCP          | Service Connection |
| Plugin       | Extension Bundle   |

***

# ✅ 十、AKS Landing Zone Demo 推荐架构

***

## Instruction：

*   AKS必须Private
*   必须RBAC

***

## Agent：

*   Plan
*   Implement
*   Review

***

## Skill：

*   deploy‑aks
*   fix‑rbac

***

## Prompt：

*   /deploy-aks-private

***

## Hook：

*   阻止 terraform destroy

***

## MCP：

*   Azure MCP Server

***

## Plugin：

*   AKS Infra Plugin（统一分发）

***

# ✅ 总结一句话

Instructions 控制行为  
Agent 控制角色  
Skill 控制能力  
Prompt 控制任务  
Hook 控制执行  
MCP 连接世界  
Plugin 统一分发
