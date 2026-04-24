# DevOps Server 实施 High Availability（增加 AT）

备注：仅新增 Application Tier（AT）时，比如从1台AT => 2台AT（做负载均衡），几乎可以做到“近零停机”。即使做数据库的 HA（主从复制），一般和 AT 类似，也是在流量切换的时候需要停机（分钟级别，当然算上变更、验证还会有额外的时间花销）

## 准备新的 AT

- 在新 AT 上安装同版本的 Azure DevOps Server
- 在安装配置时，选择加入已有的 Deployment（而不是新创建部署）

此时，不影响现网环境。我们可以在这台新 AT 上验证（localhost）

## 接入负载均衡

- 推荐 Azure LB
    * 配置健康检查（_apis/health）
    * 配置 Sticky Session（推荐，如果不配置，则 AT 之间 session 不共享，当流量到其他 AT 时，可能需要重新登录/Reconnect/SSO 的话会自动刷新，对于长连接比如 Git/Agent 有影响）
- 将所有的 AT 都加入到 LB

## 切流量

- DNS 解析切换（原来的 Client -> AT/ip，变成了 Client -> LB/ip -> AT）。此过程会发生网络波动（可能暂时找不到 IP，可能切到新IP然后连接重置），但总体一般就几分钟