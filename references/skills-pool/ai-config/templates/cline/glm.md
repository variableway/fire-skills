# Cline + GLM 配置指南

## 配置步骤

在 Cline 扩展设置中填入以下信息：

| 配置项 | 值 |
|--------|-----|
| API Provider | `OpenAI Compatible` |
| Base URL | `https://open.bigmodel.cn/api/coding/paas/v4` |
| API Key | 你的智谱 API Key |
| 模型 | 选择"使用自定义"，输入 `GLM-5.1`（或 `GLM-5`） |

## 其他配置

- 取消勾选 **Support Images**
- 调整 **Context Window Size** 为 `200000`
- 根据任务需求调整 `temperature` 等参数

## 可用模型

| 模型 | 说明 |
|------|------|
| GLM-5.1 | 最新旗舰版（Pro/Max 套餐） |
| GLM-5 | 旗舰版 |
| GLM-4.7 | 高质量通用版 |
| GLM-4.6 | 均衡版 |
| GLM-4.5 | 高性能版 |
| GLM-4.5-Air | 轻量快速版 |
