---
name: "read-pdf"
description: "读取 PDF 内容作为设计参考"
---
# 读取 PDF

当用户提供 PDF 文件作为设计参考时：

1. 用 shell 工具提取文本：
   ```bash
   # macOS
   mdls -name kMDItemNumberOfPages <file>  # 页数
   textutil -convert txt <file> -output -   # 提取文本（macOS）
   
   # 或用 pdftotext（如已安装）
   pdftotext <file> -
   ```

2. 分析提取的文本，提取设计意图、品牌信息、内容结构

3. 如文本不足以还原设计，截图逐页分析
