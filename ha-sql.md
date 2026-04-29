# Azure DevOps Server + SQL Server HA（Always On）实施手册

备注：本手册用于在现有 Azure DevOps Server（ADO Server）环境上，以 AG 自动种子（Automatic Seeding）方式建设 SQL Server Always On，并通过 Listener 平滑完成 ADO 数据层高可用切换。目标是业务侧零中断或近零感知。

适用范围：
- 现网 ADO Server 已稳定运行，计划提升 SQL 层可用性
- SQL Server 版本支持 Always On Availability Groups
- 目标是数据库高可用，不涉及 ADO 版本升级

不适用范围：
- 同一窗口同时执行跨域迁移、硬件迁移、ADO 升级
- 仅做读扩展但不要求 HA 的场景

变更目标：
- 将 ADO 数据库接入 SQL Always On AG
- 通过 Listener 提供统一连接入口
- 通过滚动切换实现业务零中断目标（前提满足时）

---

## 1. 变更前检查清单（必须逐项确认）

### 1.1 版本与架构检查

- [ ] ADO Server 与 SQL Server 版本组合受官方支持
- [ ] 主/备 SQL 实例版本、补丁级别一致
- [ ] 两节点均已启用 Windows Failover Cluster（WSFC）并状态正常
- [ ] ADO 当前数据库清单已确认（配置库、集合库、报表相关库）

### 1.2 权限与账号检查

- [ ] SQL 运维账号具备 `sysadmin` 权限
- [ ] ADO 服务账号已确认且密码可用
- [ ] 文件共享路径可用于数据库备份与恢复（主备均可访问）
- [ ] Listener 创建所需网络权限已准备完成

### 1.3 网络与端口检查

- [ ] SQL 节点间数据库镜像端点端口可达（默认常见 5022）
- [ ] ADO AT 到 SQL Listener 端口可达（默认 1433 或自定义）
- [ ] DNS 可创建 Listener 名称并及时解析
- [ ] 防火墙策略已放通客户端、节点间、集群通信端口

### 1.4 数据与风险检查

- [ ] 近 24 小时内有可用 Full Backup（用于回退兜底，而非自动种子前置要求）
- [ ] 已验证最近一次备份可恢复
- [ ] 已明确回退触发条件
- [ ] 已通知变更窗口并限制高风险变更（不强制全局冻结）

### 1.5 零中断目标前提

- [ ] ADO 为多 AT 架构，且已在 LB 后
- [ ] LB 支持节点摘除/回切（Drain）
- [ ] 可按 AT 逐台滚动更新配置与重启服务
- [ ] 若仅单 AT，需接受短时重连（无法严格零中断）

---

## 2. 推荐目标拓扑

- ADO Application Tier：1 台或多台
- SQL Server：2 节点（Primary + Secondary）
- WSFC：1 套
- AG：1 组（包含 ADO 相关数据库）
- Listener：1 个（ADO 统一连接入口）

建议：
- 生产环境优先使用同步提交（Synchronous Commit）+ 自动故障转移（两节点都满足时）
- 若跨机房延迟较大，可评估异步提交（Asynchronous Commit），但要接受 RPO 风险

---

## 3. 实施前准备（主机与SQL）

### 3.1 在两个 SQL 节点上启用 Always On

1. 打开 SQL Server Configuration Manager。
2. 在对应实例属性中启用 `Always On Availability Groups`。
3. 重启 SQL Server 服务。

### 3.2 检查 SQL 恢复模式

AG 内数据库需为 Full Recovery：

```sql
SELECT name, recovery_model_desc
FROM sys.databases
WHERE name LIKE 'Tfs_%' OR name IN ('Tfs_Configuration');
```

如非 `FULL`，先调整并重新执行完整备份。

### 3.3 规划 AG 与 Listener 参数

- AG 名称：如 `AG_ADO_PROD`
- Listener 名称：如 `ado-sql-listener`
- Listener 端口：`1433`（或按现网规范）
- 子网/IP：按网络团队分配

---

## 4. 迁移实施步骤（操作窗口）

### 4.1 在线创建 AG（Automatic Seeding）

在 Primary SQL 上通过 SSMS 向导创建 AG，选择自动种子：

1. 选择所有 ADO 相关数据库（配置库、集合库等）。
2. 副本配置中设置提交模式与故障转移模式。
3. 数据同步方式选择 `Automatic Seeding`。
4. 完成向导并确认 AG 创建成功。

说明：该阶段不要求 ADO 进入维护态。

### 4.2 验证自动种子与同步状态

在 SQL 层持续观察以下状态，直到全部正常：

- 所有目标库均已自动出现在 Secondary
- 同步状态为 `SYNCHRONIZED`（同步提交）或符合设计状态
- 无持续 `Seeding failed` / `Not Synchronizing` / `Suspended`

必要时可按数据库重试种子失败项，再继续后续步骤。

### 4.3 创建并验证 Listener

1. 在 AG 上创建 Listener（DNS 名称 + IP + 端口）。
2. 在每台 AT 上测试连通性：

```powershell
Test-NetConnection ado-sql-listener -Port 1433
```

3. 使用 SSMS 通过 Listener 名称连接并确认当前指向 Primary。

### 4.4 ADO 切到 Listener（滚动、无感）

对每台 AT 执行滚动切换：

1. 从 LB 临时摘除 1 台 AT（Drain）。
2. 在该 AT 的 Administration Console 将 SQL 连接改为 Listener 名称。
3. 按界面提示重启该 AT 的相关服务。
4. 本机验证通过后将该 AT 重新加入 LB。
5. 对下一台 AT 重复以上步骤，直至全部完成。

说明：多 AT 场景下，用户流量始终由其余 AT 承接，可实现零中断目标。

### 4.5 验证 AG 故障转移能力（建议）

1. 在低峰时执行一次计划内手动 Failover。
2. 验证 Listener 自动跟随新 Primary。
3. 验证 ADO 核心功能持续可用（登录、Git、Work Item、Pipeline）。

---

## 5. 切换后验收清单

### 5.1 功能验收

- [ ] Portal 可登录，项目列表可访问
- [ ] Git Clone/Pull/Push 正常
- [ ] Work Item 查询、新建、更新正常
- [ ] Pipeline 可排队、可执行、日志可查看

### 5.2 数据与同步验收

- [ ] AG Dashboard 显示 Healthy
- [ ] 所有 ADO 数据库均在 AG 中且同步状态正常
- [ ] 无长期 `Not Synchronizing` 或 `Suspended`

### 5.3 HA 演练（建议）

1. 在低峰时进行一次计划内手动故障转移（若 4.5 已执行可复用结果）。
2. 验证 Listener 指向新 Primary 后 ADO 功能保持正常。
3. 记录切换耗时与告警情况。

---

## 6. 回退方案（失败处理）

触发条件（任一满足）：
- ADO 长时间无法恢复读写
- AG 持续异常且短时间不可修复
- Listener 连接不稳定导致关键业务连续失败

回退步骤：
1. 将 LB 中 AT 按滚动方式逐台摘除。
2. 将该 AT 的 ADO 数据连接改回原 SQL 入口（变更前地址或别名）。
3. 验证通过后将该 AT 回加 LB，再处理下一台。
4. 如出现数据一致性风险，再启用备份恢复回退（最终兜底）。
5. 全部回切后冻结本次变更并进入复盘。

---

## 7. 常见风险与控制点

1. 自动种子对网络与磁盘吞吐敏感，可能导致种子时间过长或失败。
2. 未逐台滚动切换 AT，可能把短时重启放大为用户可见中断。
3. Listener 名称可解析但端口未放通，AT 会出现连接超时。
4. 同一窗口叠加 AT 扩容、域迁移、SQL HA，故障定位复杂度显著上升。
5. 单 AT 架构无法严格零中断，应提前向业务明确预期。

---

## 8. 变更窗口示例

| 时间点 | 动作 | 预计耗时 |
| --- | --- | --- |
| T-60m | 预检查、确认自动种子前提与回退路径 | 30m |
| T-30m | 创建 AG（Automatic Seeding）并观察同步 | 30-120m |
| T+60m | 创建 Listener + 连通性验证 | 20-30m |
| T+90m | ADO AT 滚动切换到 Listener | 20-40m |
| T+130m | 功能验收 + 故障转移演练（可延期） | 30m |

---

## 9. 交付物（建议归档）

- AG 配置截图（副本、提交模式、故障转移模式）
- Listener 配置截图（DNS、IP、端口）
- ADO 连接配置变更记录
- 验收记录（功能、同步状态、演练结果）
- 回退预案与实际执行日志（如触发）
