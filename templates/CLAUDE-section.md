## Session handover (交接工作流)

**开新对话时**：`docs/handover/next-session-prompt.md` 由 SessionStart hook
**自动载入**（`.claude/settings.json`）。按它执行，**不必等用户再说一遍**。
若 hook 未生效（hooks 被禁用、或用别的客户端打开），**自己去读那份任务书**——
它是本轮唯一的任务来源。

⚠️ **任务书只承载"当前那一条线"。** 项目的全景见
`docs/handover/README.md` §1。**「任务书做完」≠「项目做完」。**

**用户说「按交接工作流收口」时**，做这四件：

1. **重写** `docs/handover/next-session-prompt.md` 的任务段（覆盖，不追加），
   并**重画「我在哪」那棵树**（当前位置 + 完成后回到哪一级、那级还剩什么）
2. 在**当前交接件**追加一个新的 `## 0x` 状态节，写清**哪些既有结论被本轮订正了**
3. 在 **tracker** 勾选/更新对应条目（它是总账，摘要与它冲突以它为准）
4. **不要**把状态复制进 `docs/handover/README.md` 的全景节 —— 那是漂移的唯一来源

收口前跑全套门禁并把**实测数字**写进证据文档。

方法论：`docs/workflow/portable-session-handover.md`
