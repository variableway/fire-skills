#!/usr/bin/env python3
"""
Awesome List Analyzer - 分析 awesome 列表并生成工具评估报告

Usage:
    python analyze.py https://github.com/user/awesome-list
    python analyze.py /path/to/README.md --output ./analysis --export-skills
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import List, Dict, Optional
from urllib.parse import urlparse


@dataclass
class Tool:
    name: str
    category: str
    url: Optional[str]
    description: str
    tags: List[str]


@dataclass
class Category:
    name: str
    description: str
    tools: List[Tool]


class AwesomeListAnalyzer:
    def __init__(self, source: str):
        self.source = source
        self.content = ""
        self.categories: List[Category] = []
        self.temp_dir = None

    def fetch_content(self) -> str:
        """获取 awesome 列表内容"""
        if self.source.startswith(('http://', 'https://')):
            # 远程仓库
            return self._fetch_from_github()
        else:
            # 本地文件
            path = Path(self.source)
            if path.is_file():
                self.content = path.read_text(encoding='utf-8')
            elif path.is_dir():
                readme_path = path / 'README.md'
                if readme_path.exists():
                    self.content = readme_path.read_text(encoding='utf-8')
                else:
                    raise FileNotFoundError(f"README.md not found in {path}")
            else:
                raise FileNotFoundError(f"Source not found: {self.source}")
            return self.content

    def _fetch_from_github(self) -> str:
        """从 GitHub 克隆并读取 README"""
        # 创建临时目录
        self.temp_dir = tempfile.mkdtemp(prefix='awesome-analyzer-')
        
        print(f"📥 正在克隆仓库: {self.source}")
        try:
            subprocess.run(
                ['git', 'clone', '--depth', '1', self.source, self.temp_dir],
                check=True,
                capture_output=True,
                text=True
            )
        except subprocess.CalledProcessError as e:
            print(f"❌ 克隆失败: {e}")
            sys.exit(1)
        except FileNotFoundError:
            print("❌ 错误: 未找到 git 命令")
            sys.exit(1)

        readme_path = Path(self.temp_dir) / 'README.md'
        if not readme_path.exists():
            print(f"❌ 错误: 仓库中没有 README.md")
            sys.exit(1)

        self.content = readme_path.read_text(encoding='utf-8')
        return self.content

    def parse_structure(self):
        """解析 awesome 列表结构"""
        # 提取目录部分
        toc_match = re.search(r'## Contents\n+(.*?)(?=\n## |\Z)', self.content, re.DOTALL)
        if toc_match:
            toc = toc_match.group(1)
            print("📋 目录结构：")
            for line in toc.split('\n'):
                if line.strip().startswith('-'):
                    print(f"  {line.strip()}")

    def extract_categories(self) -> List[Category]:
        """提取所有分类和工具"""
        # 匹配二级标题作为分类
        category_pattern = r'## ([^#\n]+)\n\n(.*?)(?=\n## |\Z)'
        matches = re.findall(category_pattern, self.content, re.DOTALL)

        for cat_name, cat_content in matches:
            cat_name = cat_name.strip()
            # 跳过常见的非工具分类
            if cat_name in ['Contents', 'Table of Contents', 'What\'s', 'Introduction', 
                           'Contributing', 'License', 'Acknowledgements']:
                continue

            tools = self._extract_tools_from_category(cat_name, cat_content)
            if tools:  # 只添加有工具的分类
                category = Category(
                    name=cat_name,
                    description=self._extract_description(cat_content),
                    tools=tools
                )
                self.categories.append(category)

        return self.categories

    def _extract_tools_from_category(self, category: str, content: str) -> List[Tool]:
        """从分类内容中提取工具列表"""
        tools = []

        # 匹配链接格式: [name](url): description 或 - [name](url): description
        link_pattern = r'(?:^|\n)-?\s*\[([^\]]+)\]\(([^)]+)\):?\s*([^\n]*)'
        matches = re.findall(link_pattern, content)

        for name, url, desc in matches:
            # 过滤掉徽章链接
            if url.endswith(('.svg', '.png', '.jpg')) or 'shields.io' in url or 'badge' in url:
                continue
                
            tool = Tool(
                name=name.strip(),
                category=category,
                url=url.strip(),
                description=desc.strip(),
                tags=self._extract_tags(desc)
            )
            tools.append(tool)

        return tools

    def _extract_description(self, content: str) -> str:
        """提取分类描述"""
        lines = content.strip().split('\n')
        for line in lines:
            line = line.strip()
            if line and not line.startswith('-') and not line.startswith('[') and not line.startswith('#'):
                return line
        return ""

    def _extract_tags(self, description: str) -> List[str]:
        """从描述中提取标签"""
        tags = []
        keywords = {
            'free': '免费',
            'open source': '开源',
            'open-source': '开源',
            'cloud': '云',
            'desktop': '桌面',
            'web': 'Web',
            'mobile': '移动',
            'IDE': 'IDE',
            'editor': '编辑器',
            'plugin': '插件',
            'extension': '扩展',
            'AI': 'AI',
            'assistant': '助手',
            'code': '代码',
            'design': '设计',
            'UI': 'UI',
            'UX': 'UX',
            'generator': '生成器',
            'builder': '构建器',
            'framework': '框架',
            'library': '库',
            'tool': '工具',
            'platform': '平台',
        }

        desc_lower = description.lower()
        for keyword, tag in keywords.items():
            if keyword.lower() in desc_lower:
                tags.append(tag)

        return list(set(tags))

    def generate_report(self) -> str:
        """生成评估报告"""
        report = []
        report.append(f"# Awesome List 分析报告\n")
        report.append(f"> 来源: {self.source}\n")
        report.append(f"> 分析时间: {self._get_timestamp()}\n\n")

        # 统计概览
        total_tools = sum(len(cat.tools) for cat in self.categories)
        tools_with_url = sum(1 for cat in self.categories for t in cat.tools if t.url)
        
        report.append("## 📊 统计概览\n")
        report.append(f"- **分类数量**: {len(self.categories)}\n")
        report.append(f"- **工具总数**: {total_tools}\n")
        report.append(f"- **有链接工具**: {tools_with_url}\n\n")

        # 分类统计
        report.append("### 分类分布\n")
        for cat in self.categories:
            report.append(f"- {cat.name}: {len(cat.tools)} 个工具\n")
        report.append("\n")

        # 详细分析
        report.append("## 🔍 分类详细分析\n\n")

        for cat in self.categories:
            report.append(f"### {cat.name}\n")
            if cat.description:
                report.append(f"*{cat.description}*\n\n")

            if cat.tools:
                report.append("| 工具名称 | 链接 | 描述 | 标签 |\n")
                report.append("|---------|------|------|------|\n")

                for tool in cat.tools:
                    url_display = f"[链接]({tool.url})" if tool.url else "-"
                    tags_display = ", ".join(tool.tags[:3]) if tool.tags else "-"
                    desc_display = tool.description[:80] + "..." if len(tool.description) > 80 else tool.description
                    desc_display = desc_display.replace('|', '\\|').replace('\n', ' ')

                    report.append(f"| {tool.name} | {url_display} | {desc_display} | {tags_display} |\n")

            report.append("\n")

        # 重点推荐
        report.append(self._generate_recommendations())

        return "".join(report)

    def _generate_recommendations(self) -> str:
        """生成推荐部分"""
        report = []
        report.append("## ⭐ 重点推荐工具\n\n")

        # 根据分类名称识别重点分类
        priority_keywords = ['IDE', 'Editor', 'Cloud', 'Top', 'Best', 'Core', 'Essential']
        
        for cat in self.categories:
            is_priority = any(keyword.lower() in cat.name.lower() for keyword in priority_keywords)
            if is_priority or len(cat.tools) <= 5:  # 重点分类或工具较少的分类
                report.append(f"### {cat.name}\n\n")
                for tool in cat.tools[:10]:
                    url_display = f"([{tool.url}]({tool.url}))" if tool.url else ""
                    report.append(f"- **{tool.name}** {url_display}\n")
                    if tool.description:
                        report.append(f"  - {tool.description}\n")
                report.append("\n")

        return "".join(report)

    def export_json(self) -> Dict:
        """导出为 JSON 格式"""
        return {
            "source": self.source,
            "categories": [
                {
                    "name": cat.name,
                    "description": cat.description,
                    "tool_count": len(cat.tools),
                    "tools": [
                        {
                            "name": t.name,
                            "url": t.url,
                            "description": t.description,
                            "tags": t.tags
                        }
                        for t in cat.tools
                    ]
                }
                for cat in self.categories
            ]
        }

    def export_skills(self, output_dir: Path):
        """导出为 skill 格式"""
        skills_dir = output_dir / 'skills'
        skills_dir.mkdir(parents=True, exist_ok=True)

        for cat in self.categories:
            if not cat.tools:
                continue

            skill_content = f"""# {cat.name}

> 从 awesome list 提取的工具列表
> 来源: {self.source}

## 简介

{cat.description}

## 工具列表 ({len(cat.tools)} 个)

"""
            for tool in cat.tools:
                if tool.url:
                    skill_content += f"- [{tool.name}]({tool.url})\n"
                else:
                    skill_content += f"- {tool.name}\n"
                if tool.description:
                    skill_content += f"  - {tool.description}\n"
                if tool.tags:
                    skill_content += f"  - 标签: {', '.join(tool.tags)}\n"

            # 保存为 markdown
            filename = re.sub(r'[^\w\s-]', '', cat.name).strip().replace(' ', '-').lower()
            (skills_dir / f"{filename}.md").write_text(skill_content, encoding='utf-8')

        print(f"✅ 已导出 {len(self.categories)} 个分类到 {skills_dir}")

    def _get_timestamp(self) -> str:
        """获取当前时间戳"""
        from datetime import datetime
        return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    def cleanup(self):
        """清理临时文件"""
        if self.temp_dir and os.path.exists(self.temp_dir):
            import shutil
            shutil.rmtree(self.temp_dir)
            print(f"🧹 已清理临时目录")


def main():
    parser = argparse.ArgumentParser(
        description='分析 awesome 列表仓库，提取工具并生成评估报告',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python analyze.py https://github.com/techiediaries/awesome-vibe-coding
  python analyze.py ./my-awesome-list/README.md --output ./analysis --export-skills
        """
    )
    
    parser.add_argument('source', help='GitHub 仓库 URL 或本地 README.md 路径')
    parser.add_argument('-o', '--output', default='./awesome-analysis', 
                       help='输出目录 (默认: ./awesome-analysis)')
    parser.add_argument('-s', '--export-skills', action='store_true',
                       help='导出为 skill 格式')
    parser.add_argument('-m', '--max-tools', type=int, default=100,
                       help='每类最大工具数 (默认: 100)')
    parser.add_argument('-f', '--format', choices=['markdown', 'json', 'all'], default='all',
                       help='输出格式 (默认: all)')
    parser.add_argument('--keep-temp', action='store_true',
                       help='保留临时文件（调试用）')

    args = parser.parse_args()

    print("🔍 Awesome List Analyzer")
    print("=" * 50)

    # 创建分析器
    analyzer = AwesomeListAnalyzer(args.source)

    try:
        # 获取内容
        analyzer.fetch_content()
        
        # 解析结构
        print("\n📋 解析目录结构...")
        analyzer.parse_structure()

        # 提取分类和工具
        print("\n📦 提取工具数据...")
        categories = analyzer.extract_categories()
        
        total_tools = sum(len(cat.tools) for cat in categories)
        print(f"✅ 发现 {len(categories)} 个分类，共 {total_tools} 个工具")

        # 创建输出目录
        output_path = Path(args.output)
        output_path.mkdir(parents=True, exist_ok=True)

        # 生成 Markdown 报告
        if args.format in ['markdown', 'all']:
            print("\n📝 生成 Markdown 报告...")
            report = analyzer.generate_report()
            report_path = output_path / 'analysis.md'
            report_path.write_text(report, encoding='utf-8')
            print(f"✅ 报告已保存: {report_path}")

        # 导出 JSON
        if args.format in ['json', 'all']:
            print("\n📊 导出 JSON 数据...")
            data = analyzer.export_json()
            json_path = output_path / 'summary.json'
            json_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding='utf-8')
            print(f"✅ 数据已保存: {json_path}")

        # 导出 Skills
        if args.export_skills:
            print("\n📤 导出为 skill 格式...")
            analyzer.export_skills(output_path)

        # 打印摘要
        print("\n" + "=" * 50)
        print("📊 分析摘要")
        print("=" * 50)
        for cat in categories[:5]:
            print(f"- {cat.name}: {len(cat.tools)} 个工具")
        if len(categories) > 5:
            print(f"... 还有 {len(categories) - 5} 个分类")
        
        print(f"\n📁 输出目录: {output_path.absolute()}")

    finally:
        # 清理
        if not args.keep_temp:
            analyzer.cleanup()


if __name__ == "__main__":
    main()
