package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

// Skill represents a single AI music skill/project
type Skill struct {
	ID          int      `json:"id"`
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Type        string   `json:"type"`
	GitHub      string   `json:"github"`
	ClawHub     string   `json:"clawhub"`
	MCPMarket   string   `json:"mcp_market"`
	License     string   `json:"license"`
	Language    string   `json:"language"`
	Stars       string   `json:"stars"`
	Tags        []string `json:"tags"`
	Category    string   `json:"category"`
}

// SkillsData represents the root JSON structure
type SkillsData struct {
	Metadata   Metadata `json:"metadata"`
	Skills     []Skill  `json:"skills"`
	GitHubOnly []string `json:"github_only"`
}

// Metadata represents the metadata section
type Metadata struct {
	Title       string `json:"title"`
	GeneratedAt string `json:"generated_at"`
	Description string `json:"description"`
	Source      string `json:"source"`
}

const (
	defaultJSONURL = "https://raw.githubusercontent.com/innate-skills-exp/main/music/phase1-快速验证/skill-collector-task3/ai-music-skills.json"
	version        = "1.0.0"
)

var jsonPath string

func main() {
	flag.StringVar(&jsonPath, "f", "ai-music-skills.json", "Path to the JSON data file")
	flag.Parse()

	if len(os.Args) < 2 {
		printUsage()
		os.Exit(0)
	}

	cmd := os.Args[1]

	switch cmd {
	case "version", "-v", "--version":
		fmt.Printf("ai-music-skills-cli v%s\n", version)
	case "list":
		handleList()
	case "clone":
		handleClone()
	case "clone-all":
		handleCloneAll()
	case "search":
		handleSearch()
	case "categories":
		handleCategories()
	case "github-list":
		handleGitHubList()
	case "download-json":
		handleDownloadJSON()
	default:
		printUsage()
	}
}

func printUsage() {
	fmt.Println(`AI Music Skills CLI - 管理AI音乐开源项目的命令行工具

用法: go run main.go <命令> [选项]

命令:
  list              列出所有30个AI Music项目
  clone <id|name>   克隆指定GitHub项目到当前目录
  clone-all         克隆所有GitHub项目到 ./ai-music-repos/ 目录
  search <keyword>  按关键词搜索项目(名称/描述/标签)
  categories        按分类统计项目
  github-list       只列出有GitHub链接的项目
  download-json     从远程下载最新的JSON数据文件
  version           显示版本信息

选项:
  -f <path>         指定JSON文件路径 (默认: ai-music-skills.json)

示例:
  go run main.go list
  go run main.go clone 1
  go run main.go clone Amphion
  go run main.go clone-all
  go run main.go search diffusion
  go run main.go categories
  go run main.go github-list
`)
}

func loadData() (*SkillsData, error) {
	f, err := os.Open(jsonPath)
	if err != nil {
		return nil, fmt.Errorf("无法打开JSON文件 %s: %w\n提示: 可以使用 'download-json' 命令下载数据文件", jsonPath, err)
	}
	defer f.Close()

	var data SkillsData
	if err := json.NewDecoder(f).Decode(&data); err != nil {
		return nil, fmt.Errorf("解析JSON失败: %w", err)
	}
	return &data, nil
}

func handleList() {
	data, err := loadData()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	fmt.Printf("\n%s\n", data.Metadata.Title)
	fmt.Printf("生成日期: %s | %s\n\n", data.Metadata.GeneratedAt, data.Metadata.Description)
	fmt.Println(strings.Repeat("=", 120))

	for _, s := range data.Skills {
		printSkill(s)
	}
	fmt.Printf("\n总计: %d 个项目\n", len(data.Skills))
}

func printSkill(s Skill) {
	githubMark := ""
	if s.GitHub != "" {
		githubMark = "⭐"
	}
	clawhubMark := ""
	if s.ClawHub != "" {
		clawhubMark = "🐾"
	}

	fmt.Printf("\n[%02d] %s %s%s\n", s.ID, s.Name, githubMark, clawhubMark)
	fmt.Printf("     类型: %-10s | 分类: %-12s | 语言: %-8s | Stars: %-8s | 许可: %s\n",
		s.Type, s.Category, s.Language, s.Stars, s.License)
	fmt.Printf("     标签: %s\n", strings.Join(s.Tags, ", "))
	fmt.Printf("     描述: %s\n", truncate(s.Description, 100))
	if s.GitHub != "" {
		fmt.Printf("     GitHub: %s\n", s.GitHub)
	}
	if s.ClawHub != "" {
		fmt.Printf("     ClawHub: %s\n", s.ClawHub)
	}
}

func truncate(s string, max int) string {
	if len(s) <= max {
		return s
	}
	return s[:max] + "..."
}

func handleClone() {
	if len(os.Args) < 3 {
		fmt.Println("用法: go run main.go clone <id|name>")
		os.Exit(1)
	}

	data, err := loadData()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	target := os.Args[2]
	var found *Skill

	// Try match by ID first
	for i := range data.Skills {
		if fmt.Sprintf("%d", data.Skills[i].ID) == target {
			found = &data.Skills[i]
			break
		}
	}

	// Then try match by name (case-insensitive contains)
	if found == nil {
		for i := range data.Skills {
			if strings.Contains(strings.ToLower(data.Skills[i].Name), strings.ToLower(target)) {
				found = &data.Skills[i]
				break
			}
		}
	}

	if found == nil {
		fmt.Printf("未找到匹配的项目: %s\n", target)
		os.Exit(1)
	}

	if found.GitHub == "" {
		fmt.Printf("项目 '%s' 没有GitHub仓库链接\n", found.Name)
		if found.ClawHub != "" {
			fmt.Printf("ClawHub页面: %s\n", found.ClawHub)
		}
		os.Exit(1)
	}

	cloneRepo(found.GitHub, "")
}

func handleCloneAll() {
	data, err := loadData()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	targetDir := "ai-music-repos"
	if err := os.MkdirAll(targetDir, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "创建目录失败: %v\n", err)
		os.Exit(1)
	}

	var githubSkills []Skill
	for _, s := range data.Skills {
		if s.GitHub != "" {
			githubSkills = append(githubSkills, s)
		}
	}

	fmt.Printf("准备克隆 %d 个GitHub项目到 %s/\n\n", len(githubSkills), targetDir)

	success := 0
	failed := 0
	for _, s := range githubSkills {
		fmt.Printf("[%d/%d] 克隆 %s ...\n", success+failed+1, len(githubSkills), s.Name)
		if cloneRepo(s.GitHub, targetDir) {
			success++
		} else {
			failed++
		}
	}

	fmt.Printf("\n完成! 成功: %d, 失败: %d\n", success, failed)
	fmt.Printf("项目保存在: %s/\n", targetDir)
}

func cloneRepo(repoURL, targetDir string) bool {
	// Extract repo name from URL
	parts := strings.Split(strings.TrimSuffix(repoURL, "/"), "/")
	if len(parts) < 2 {
		fmt.Fprintf(os.Stderr, "无效的GitHub URL: %s\n", repoURL)
		return false
	}

	repoName := parts[len(parts)-1]
	if targetDir != "" {
		repoName = filepath.Join(targetDir, repoName)
	}

	// Check if already exists
	if _, err := os.Stat(repoName); err == nil {
		fmt.Printf("  目录已存在，跳过: %s\n", repoName)
		return true
	}

	cmd := exec.Command("git", "clone", "--depth", "1", repoURL, repoName)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "  克隆失败: %v\n", err)
		return false
	}
	return true
}

func handleSearch() {
	if len(os.Args) < 3 {
		fmt.Println("用法: go run main.go search <keyword>")
		os.Exit(1)
	}

	data, err := loadData()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	keyword := strings.ToLower(os.Args[2])
	var results []Skill

	for _, s := range data.Skills {
		if strings.Contains(strings.ToLower(s.Name), keyword) ||
			strings.Contains(strings.ToLower(s.Description), keyword) ||
			strings.Contains(strings.ToLower(s.Category), keyword) ||
			containsTag(s.Tags, keyword) {
			results = append(results, s)
		}
	}

	if len(results) == 0 {
		fmt.Printf("未找到匹配 '%s' 的项目\n", keyword)
		return
	}

	fmt.Printf("\n找到 %d 个匹配 '%s' 的项目:\n", len(results), keyword)
	fmt.Println(strings.Repeat("-", 80))
	for _, s := range results {
		printSkill(s)
	}
}

func containsTag(tags []string, keyword string) bool {
	for _, t := range tags {
		if strings.Contains(strings.ToLower(t), keyword) {
			return true
		}
	}
	return false
}

func handleCategories() {
	data, err := loadData()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	cats := make(map[string][]Skill)
	for _, s := range data.Skills {
		cats[s.Category] = append(cats[s.Category], s)
	}

	fmt.Println("\n按分类统计:")
	fmt.Println(strings.Repeat("=", 60))
	for cat, skills := range cats {
		githubCount := 0
		for _, s := range skills {
			if s.GitHub != "" {
				githubCount++
			}
		}
		fmt.Printf("  %-20s %2d 个项目 (GitHub: %d)\n", cat, len(skills), githubCount)
	}
	fmt.Println(strings.Repeat("=", 60))

	// Type stats
	fmt.Println("\n按类型统计:")
	types := make(map[string]int)
	for _, s := range data.Skills {
		types[s.Type]++
	}
	for t, count := range types {
		fmt.Printf("  %-10s %d 个\n", t, count)
	}
}

func handleGitHubList() {
	data, err := loadData()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	fmt.Println("\n有GitHub链接的项目列表:")
	fmt.Println(strings.Repeat("=", 100))

	count := 0
	for _, s := range data.Skills {
		if s.GitHub != "" {
			count++
			fmt.Printf("[%02d] %-35s %s\n", s.ID, s.Name, s.GitHub)
		}
	}
	fmt.Println(strings.Repeat("=", 100))
	fmt.Printf("共 %d 个项目有GitHub链接\n", count)
}

func handleDownloadJSON() {
	// Try multiple sources
	sources := []string{
		defaultJSONURL,
	}

	// Also check if there's a local remote URL provided via env
	if envURL := os.Getenv("SKILLS_JSON_URL"); envURL != "" {
		sources = append([]string{envURL}, sources...)
	}

	client := &http.Client{Timeout: 30 * time.Second}

	var lastErr error
	for _, url := range sources {
		fmt.Printf("尝试下载: %s\n", url)
		resp, err := client.Get(url)
		if err != nil {
			lastErr = err
			continue
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			lastErr = fmt.Errorf("HTTP %d", resp.StatusCode)
			continue
		}

		data, err := io.ReadAll(resp.Body)
		if err != nil {
			lastErr = err
			continue
		}

		// Validate JSON
		var skillsData SkillsData
		if err := json.Unmarshal(data, &skillsData); err != nil {
			lastErr = err
			continue
		}

		if err := os.WriteFile(jsonPath, data, 0644); err != nil {
			fmt.Fprintf(os.Stderr, "保存文件失败: %v\n", err)
			os.Exit(1)
		}

		fmt.Printf("✓ 成功下载并保存到: %s\n", jsonPath)
		fmt.Printf("  包含 %d 个项目\n", len(skillsData.Skills))
		return
	}

	fmt.Fprintf(os.Stderr, "下载失败: %v\n", lastErr)
	fmt.Println("\n提示: 你可以手动下载JSON文件并放在当前目录")
	os.Exit(1)
}

// isWindows checks if running on Windows
func isWindows() bool {
	return runtime.GOOS == "windows"
}

// placeholder to avoid unused import warning for isWindows
var _ = isWindows
