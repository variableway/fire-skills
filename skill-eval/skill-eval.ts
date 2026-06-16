/**
 * Skill Evaluation System
 * 
 * A simple evaluation system for assessing frontend development skills
 * based on component quality, developer experience, project fit, and performance.
 */

interface SkillEvaluation {
  name: string
  description: string
  score: number
  criteria: EvaluationCriteria
  recommendations: string[]
}

interface EvaluationCriteria {
  componentQuality: number // 0-10
  developerExperience: number // 0-10
  projectFit: number // 0-10
  performance: number // 0-10
}

interface SkillConfig {
  name: string
  description: string
  techStack: string[]
  strengths: string[]
  useCases: string[]
}

// Top 15 Skills Configuration
const TOP_15_SKILLS: SkillConfig[] = [
  {
    name: "shadcn-ui",
    description: "Official shadcn/ui component library with 57+ base components",
    techStack: ["Next.js 16", "React 19", "Tailwind CSS", "Radix UI"],
    strengths: ["Copy-paste model", "Full customization", "CSS variable theming"],
    useCases: ["Foundation for all UI components"]
  },
  {
    name: "reui",
    description: "1000+ components across 68 categories with 17 in-house primitives",
    techStack: ["Next.js", "React 18+", "Tailwind CSS v4"],
    strengths: ["Advanced data components", "Dual library support"],
    useCases: ["Complex data-heavy applications"]
  },
  {
    name: "awesome-shadcn-ui",
    description: "Community resource directory with 60+ components",
    techStack: ["Next.js 16", "React 19", "Tailwind CSS v4"],
    strengths: ["Directory/catalog patterns", "Search/filter/sort components"],
    useCases: ["Directory and showcase interfaces"]
  },
  {
    name: "admin-nextjs-starter",
    description: "Production-ready admin dashboard with Next.js 16 App Router",
    techStack: ["Next.js 16", "@innate/ui", "next-themes"],
    strengths: ["Route groups", "Scene catalog system", "Theme toggle"],
    useCases: ["Admin panels with sidebar navigation"]
  },
  {
    name: "admin-tanstack-starter",
    description: "Admin dashboard with TanStack Router + Vite",
    techStack: ["TanStack Router", "Vite", "@innate/ui"],
    strengths: ["File-based routing", "Fast development"],
    useCases: ["Rapid admin dashboard development"]
  },
  {
    name: "shadcn-ui-blocks",
    description: "Pre-built landing, auth, mail, and chat page blocks",
    techStack: ["Next.js", "@innate/ui", "block components"],
    strengths: ["Data-driven blocks", "Reusable patterns"],
    useCases: ["Quick page assembly"]
  },
  {
    name: "tweakcn",
    description: "Theme editor with AI integration and live preview",
    techStack: ["Next.js", "shadcn/ui"],
    strengths: ["Visual theme customization", "AI-assisted design"],
    useCases: ["Theme prototyping and customization"]
  },
  {
    name: "shadcn-dashboard",
    description: "30+ pages with landing + dashboard, dual framework support",
    techStack: ["Next.js", "React", "shadcn/ui"],
    strengths: ["Comprehensive page collection", "Production-ready"],
    useCases: ["Full-featured admin dashboards"]
  },
  {
    name: "velocify",
    description: "AI SaaS starter with Clerk + Stripe + Claude integration",
    techStack: ["Next.js", "Clerk", "Stripe", "AI SDK"],
    strengths: ["Authentication", "Payments", "AI integration"],
    useCases: ["SaaS applications with auth and payments"]
  },
  {
    name: "ai-sdk-rag",
    description: "RAG chatbot starter with vector database integration",
    techStack: ["Next.js", "AI SDK", "vector DB"],
    strengths: ["AI-powered chat", "Document retrieval"],
    useCases: ["AI chatbots and document Q&A"]
  },
  {
    name: "nextra-starter",
    description: "Documentation site with i18n support",
    techStack: ["Next.js", "Nextra", "MDX"],
    strengths: ["Internationalization", "Documentation patterns"],
    useCases: ["Technical documentation sites"]
  },
  {
    name: "shadcn-cheatsheet",
    description: "Interactive component reference and playground",
    techStack: ["Next.js", "shadcn/ui"],
    strengths: ["Live component examples", "Interactive demos"],
    useCases: ["Component reference and learning"]
  },
  {
    name: "ui-creative-tim",
    description: "Premium marketing, e-commerce, and Web3 blocks",
    techStack: ["Next.js", "React", "shadcn/ui"],
    strengths: ["High-quality design", "Business-focused components"],
    useCases: ["Marketing sites and e-commerce"]
  },
  {
    name: "form-builder",
    description: "Advanced form patterns with React Hook Form + Zod",
    techStack: ["React Hook Form", "Zod", "shadcn/ui"],
    strengths: ["Form validation", "Multi-step forms"],
    useCases: ["Data entry applications"]
  },
  {
    name: "data-table",
    description: "Advanced data table with sorting, filtering, pagination",
    techStack: ["TanStack Table", "shadcn/ui"],
    strengths: ["Inline editing", "Bulk actions"],
    useCases: ["Data-heavy admin interfaces"]
  }
]

/**
 * Evaluate a skill based on criteria
 */
function evaluateSkill(
  skill: SkillConfig,
  criteria: EvaluationCriteria
): SkillEvaluation {
  const score = (
    criteria.componentQuality * 0.3 +
    criteria.developerExperience * 0.3 +
    criteria.projectFit * 0.25 +
    criteria.performance * 0.15
  )

  const recommendations = generateRecommendations(skill, criteria)

  return {
    name: skill.name,
    description: skill.description,
    score: Math.round(score * 100) / 100,
    criteria,
    recommendations
  }
}

/**
 * Generate recommendations based on evaluation
 */
function generateRecommendations(
  skill: SkillConfig,
  criteria: EvaluationCriteria
): string[] {
  const recommendations: string[] = []

  if (criteria.componentQuality < 7) {
    recommendations.push("Consider enhancing component documentation")
  }

  if (criteria.developerExperience < 7) {
    recommendations.push("Improve setup documentation and examples")
  }

  if (criteria.projectFit < 7) {
    recommendations.push("Better integration with innate-base template")
  }

  if (criteria.performance < 7) {
    recommendations.push("Optimize bundle size and rendering performance")
  }

  // Skill-specific recommendations
  if (skill.name === "shadcn-ui") {
    recommendations.push("Consider adding more block components")
  }

  if (skill.name === "reui") {
    recommendations.push("Improve TypeScript definitions for advanced components")
  }

  if (skill.name.includes("admin")) {
    recommendations.push("Add more scene catalog examples")
  }

  return recommendations
}

/**
 * Compare multiple skills
 */
function compareSkills(
  skills: SkillConfig[],
  criteriaList: EvaluationCriteria[]
): SkillEvaluation[] {
  return skills.map((skill, index) => 
    evaluateSkill(skill, criteriaList[index] || getDefaultCriteria())
  )
}

/**
 * Get default criteria for evaluation
 */
function getDefaultCriteria(): EvaluationCriteria {
  return {
    componentQuality: 8,
    developerExperience: 8,
    projectFit: 8,
    performance: 8
  }
}

/**
 * Generate evaluation report
 */
function generateReport(evaluations: SkillEvaluation[]): string {
  let report = "# Skill Evaluation Report\n\n"
  
  report += "## Summary\n\n"
  report += `Total Skills Evaluated: ${evaluations.length}\n`
  
  const avgScore = evaluations.reduce((sum, e) => sum + e.score, 0) / evaluations.length
  report += `Average Score: ${avgScore.toFixed(2)}\n\n`
  
  report += "## Rankings\n\n"
  const sorted = [...evaluations].sort((a, b) => b.score - a.score)
  sorted.forEach((evaluation, index) => {
    report += `${index + 1}. ${evaluation.name}: ${evaluation.score}\n`
  })
  
  report += "\n## Detailed Evaluations\n\n"
  evaluations.forEach(evaluation => {
    report += `### ${evaluation.name}\n\n`
    report += `**Score**: ${evaluation.score}\n\n`
    report += `**Criteria**:\n`
    report += `- Component Quality: ${evaluation.criteria.componentQuality}/10\n`
    report += `- Developer Experience: ${evaluation.criteria.developerExperience}/10\n`
    report += `- Project Fit: ${evaluation.criteria.projectFit}/10\n`
    report += `- Performance: ${evaluation.criteria.performance}/10\n\n`
    
    if (evaluation.recommendations.length > 0) {
      report += `**Recommendations**:\n`
      evaluation.recommendations.forEach(rec => {
        report += `- ${rec}\n`
      })
      report += "\n"
    }
  })
  
  return report
}

/**
 * Main evaluation function
 */
function runEvaluation(): void {
  console.log("Starting Skill Evaluation...\n")
  
  // Default criteria for all skills
  const defaultCriteria: EvaluationCriteria = {
    componentQuality: 8,
    developerExperience: 8,
    projectFit: 8,
    performance: 8
  }
  
  // Evaluate all skills
  const evaluations = TOP_15_SKILLS.map(skill => 
    evaluateSkill(skill, defaultCriteria)
  )
  
  // Generate report
  const report = generateReport(evaluations)
  
  // Output report
  console.log(report)
  
  // Save report to file
  const fs = require('fs')
  const reportPath = './skill-evaluation-report.md'
  fs.writeFileSync(reportPath, report)
  console.log(`\nReport saved to ${reportPath}`)
}

// Export functions for external use
export {
  evaluateSkill,
  compareSkills,
  generateReport,
  runEvaluation,
  TOP_15_SKILLS,
  SkillEvaluation,
  EvaluationCriteria,
  SkillConfig
}

// Run evaluation if executed directly
if (require.main === module) {
  runEvaluation()
}
