---
description: 在代码中添加 TODO 注释
argument-hint: [TODO 消息，使用 ! 表示高优先级]
allowed-tools: Read, Edit
---

基于以下内容添加 TODO 注释: $ARGUMENTS

## 优先级检测

- 开头有 `!` → 高优先级: `// TODO [HIGH]: 消息`
- 开头有 `?` → 待讨论: `// TODO [DISCUSS]: 消息`
- 无标记 → 普通: `// TODO: 消息`

## 按语言的注释格式

检测文件类型并使用适当的注释语法:

- JavaScript/TypeScript: `// TODO: 消息`
- Python: `# TODO: 消息`
- HTML: `<!-- TODO: 消息 -->`
- CSS: `/* TODO: 消息 */`
- Shell: `# TODO: 消息`

## 步骤

1. 识别文件上下文（当前打开或最近编辑的文件）
2. 解析消息并检测优先级
3. 适当格式化 TODO 注释
4. 添加到逻辑位置:
   - 如果上下文清晰，添加在相关代码附近
   - 否则添加到函数/块顶部
5. 确认添加

## 示例

输入: `/todo 修复空值检查`
输出: `// TODO: 修复空值检查`

输入: `/todo ! 关键的安全修复`
输出: `// TODO [HIGH]: 关键的安全修复`

输入: `/todo ? 这里应该使用异步吗`
输出: `// TODO [DISCUSS]: 这里应该使用异步吗`

## 输出

简要确认:
```
✓ 已在 [文件]:[行号] 添加 TODO
```
