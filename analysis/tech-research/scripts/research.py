#!/usr/bin/env python3
"""
Tech Research Skill - 技术问题解决方案搜索与分析

Usage:
    python research.py "如何优化 Webpack 构建速度"
    python research.py "React 状态管理方案对比" --compare
    python research.py "Docker 最佳实践" --results 10 --output report.md
"""

import argparse
import json
import sys
import re
from typing import List, Dict, Optional
from urllib.parse import urlparse


def search_duckduckgo(query: str, max_results: int = 5) -> List[Dict]:
    """使用 DuckDuckGo 搜索"""
    try:
        from ddgs import DDGS
    except ImportError:
        try:
            from duckduckgo_search import DDGS
        except ImportError:
            print("Error: ddgs not installed.", file=sys.stderr)
            print("Run: pip install ddgs", file=sys.stderr)
            sys.exit(1)

    results = []
    try:
        with DDGS() as ddgs:
            for result in ddgs.text(query, max_results=max_results):
                results.append({
                    "title": result.get("title", ""),
                    "href": result.get("href", ""),
                    "body": result.get("body", "")
                })
    except Exception as e:
        print(f"Search error: {e}", file=sys.stderr)

    return results


def fetch_page_content(url: str, timeout: int = 10) -> str:
    """抓取网页内容"""
    try:
        import requests
        from bs4 import BeautifulSoup
    except ImportError:
        return ""

    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        }
        response = requests.get(url, headers=headers, timeout=timeout)
        response.raise_for_status()

        soup = BeautifulSoup(response.content, "html.parser")

        # 移除脚本和样式
        for script in soup(["script", "style", "nav", "footer", "header"]):
            script.decompose()

        # 尝试获取主要内容
        main_content = soup.find("main") or soup.find("article") or soup.find("div", class_="content")
        if main_content:
            text = main_content.get_text(separator="\n", strip=True)
        else:
            text = soup.get_text(separator="\n", strip=True)

        # 清理文本
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        text = "\n".join(lines[:100])  # 限制长度

        return text
    except Exception as e:
        return f"[Failed to fetch: {e}]"


def analyze_with_llm(query: str, search_results: List[Dict], compare_mode: bool = False) -> str:
    """使用 LLM 分析搜索结果并生成报告"""

    # 构建搜索结果摘要
    results_summary = []
    for i, result in enumerate(search_results, 1):
        results_summary.append(f"\n[{i}] {result['title']}\nURL: {result['href']}\n摘要: {result['body']}")

    search_content = "\n".join(results_summary)

    # 构建提示词
    mode_instruction = "对比分析不同方案的优劣" if compare_mode else "分析并推荐最佳解决方案"

    prompt = f"""你是一个技术专家，擅长分析技术问题并提供结构化的解决方案报告。

用户问题：{query}

搜索到的相关信息：
{search_content}

请基于以上信息，生成一份结构化的技术调研报告，要求：

1. **问题概述**：提炼用户问题的核心要点和关键挑战

2. **解决方案列表**：列出搜索到的所有解决方案，每种方案包含：
   - 方案名称
   - 简要描述
   - 核心特点

3. **方案对比分析**：对每个方案从以下维度进行分析（用表格呈现）：
   - **技术成熟度**：⭐ 评分（1-5星），考虑稳定性、社区活跃度、维护状态
   - **优点**：该方案的主要优势
   - **缺点**：该方案的局限性
   - **适用场景**：什么情况下适合使用
   - **学习曲线**：低/中/高，上手难度评估

4. **推荐方案**：
   - 综合评分最高的方案
   - 推荐理由（至少3点）
   - 风险提示

5. **实施建议**：
   - 具体的执行步骤
   - 最佳实践
   - 常见陷阱和注意事项

6. **参考来源**：
   - 列出所有引用的来源链接

请用 Markdown 格式输出报告，确保内容专业、客观、实用。"""

    # 尝试使用 LLM 生成报告
    try:
        # 尝试使用 anthropic
        import anthropic
        client = anthropic.Anthropic()
        response = client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=4000,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text
    except Exception as e1:
        try:
            # 尝试使用 openai
            import openai
            response = openai.chat.completions.create(
                model="gpt-4",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=4000
            )
            return response.choices[0].message.content
        except Exception as e2:
            # 如果没有 LLM API，返回结构化模板
            return generate_template_report(query, search_results, compare_mode)


def generate_template_report(query: str, search_results: List[Dict], compare_mode: bool) -> str:
    """当没有 LLM API 时，生成模板报告"""

    report = f"""# {query} - 技术调研报告

## 问题概述

针对"{query}"，本报告整理了相关的技术解决方案和最佳实践。

## 解决方案列表

"""

    for i, result in enumerate(search_results, 1):
        report += f"""### {i}. {result['title']}

{result['body']}

**来源**: [{urlparse(result['href']).netloc}]({result['href']})

---

"""

    report += """## 方案对比分析

| 维度 | 说明 |
|------|------|
| **技术成熟度** | 建议查看方案的 GitHub stars、最后更新时间、社区活跃度 |
| **优缺点** | 建议阅读官方文档和社区讨论 |
| **适用场景** | 根据项目规模、团队技术栈、性能要求等因素评估 |
| **学习曲线** | 参考官方教程的复杂度和上手时间 |

## 推荐方案

基于搜索结果，建议：
1. 仔细阅读上述各方案的官方文档
2. 根据项目实际需求进行技术选型
3. 考虑团队的技术能力和维护成本
4. 建议先进行小规模 POC 验证

## 实施建议

1. **调研阶段**：深入了解各方案的设计理念和使用场景
2. **POC 阶段**：在小型项目中验证方案的可行性
3. **评估阶段**：从性能、维护性、扩展性等维度评估
4. **实施阶段**：制定详细的迁移或实施计划

## 参考来源

"""

    for result in search_results:
        report += f"- [{result['title']}]({result['href']})\n"

    report += """
---

*注：本报告基于 Web 搜索结果自动生成，建议结合官方文档和实际项目需求进行综合判断。*
"""

    return report


def main():
    parser = argparse.ArgumentParser(
        description="技术问题解决方案搜索与分析工具"
    )
    parser.add_argument("query", help="搜索查询内容")
    parser.add_argument("--compare", action="store_true", help="启用对比模式")
    parser.add_argument("--results", type=int, default=5, help="搜索结果数量 (默认: 5)")
    parser.add_argument("--output", "-o", help="输出文件路径")
    parser.add_argument("--format", choices=["markdown", "json"], default="markdown", help="输出格式")
    parser.add_argument("--fetch-content", action="store_true", help="抓取详细内容（较慢）")

    args = parser.parse_args()

    print(f"🔍 正在搜索: {args.query}")
    print(f"📊 结果数量: {args.results}")
    print()

    # 执行搜索
    search_results = search_duckduckgo(args.query, args.results)

    if not search_results:
        print("❌ 未找到相关结果，请尝试其他关键词。", file=sys.stderr)
        sys.exit(1)

    print(f"✅ 找到 {len(search_results)} 个结果")
    print("🤖 正在分析并生成报告...")
    print()

    # 如果需要抓取详细内容
    if args.fetch_content:
        print("📄 正在抓取详细内容（可能需要一些时间）...")
        for result in search_results:
            content = fetch_page_content(result["href"])
            result["content"] = content[:2000]  # 限制内容长度

    # 生成报告
    if args.format == "json":
        report = json.dumps(search_results, ensure_ascii=False, indent=2)
    else:
        report = analyze_with_llm(args.query, search_results, args.compare)

    # 输出报告
    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(report)
        print(f"✅ 报告已保存到: {args.output}")
    else:
        print("\n" + "=" * 80)
        print(report)
        print("=" * 80)


if __name__ == "__main__":
    main()
