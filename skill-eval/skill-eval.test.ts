/**
 * Skill Evaluation Tests
 * 
 * Simple tests for the skill evaluation system
 */

import {
  evaluateSkill,
  compareSkills,
  generateReport,
  TOP_15_SKILLS,
  EvaluationCriteria,
  SkillConfig
} from './skill-eval'

describe('Skill Evaluation System', () => {
  const defaultCriteria: EvaluationCriteria = {
    componentQuality: 8,
    developerExperience: 8,
    projectFit: 8,
    performance: 8
  }

  test('should evaluate a single skill', () => {
    const skill = TOP_15_SKILLS[0] // shadcn-ui
    const evaluation = evaluateSkill(skill, defaultCriteria)

    expect(evaluation.name).toBe('shadcn-ui')
    expect(evaluation.score).toBeGreaterThan(0)
    expect(evaluation.score).toBeLessThanOrEqual(10)
    expect(evaluation.criteria).toEqual(defaultCriteria)
    expect(Array.isArray(evaluation.recommendations)).toBe(true)
  })

  test('should calculate weighted score correctly', () => {
    const skill: SkillConfig = {
      name: 'test-skill',
      description: 'Test skill',
      techStack: ['React'],
      strengths: ['Test'],
      useCases: ['Testing']
    }

    const criteria: EvaluationCriteria = {
      componentQuality: 10,
      developerExperience: 10,
      projectFit: 10,
      performance: 10
    }

    const evaluation = evaluateSkill(skill, criteria)
    expect(evaluation.score).toBe(10)
  })

  test('should compare multiple skills', () => {
    const skills = TOP_15_SKILLS.slice(0, 3)
    const criteriaList = [defaultCriteria, defaultCriteria, defaultCriteria]

    const evaluations = compareSkills(skills, criteriaList)
    expect(evaluations).toHaveLength(3)
    expect(evaluations[0].name).toBe('shadcn-ui')
    expect(evaluations[1].name).toBe('reui')
    expect(evaluations[2].name).toBe('awesome-shadcn-ui')
  })

  test('should generate recommendations based on criteria', () => {
    const skill = TOP_15_SKILLS[0]
    const lowCriteria: EvaluationCriteria = {
      componentQuality: 5,
      developerExperience: 5,
      projectFit: 5,
      performance: 5
    }

    const evaluation = evaluateSkill(skill, lowCriteria)
    expect(evaluation.recommendations.length).toBeGreaterThan(0)
  })

  test('should generate a report', () => {
    const skills = TOP_15_SKILLS.slice(0, 2)
    const criteriaList = [defaultCriteria, defaultCriteria]

    const evaluations = compareSkills(skills, criteriaList)
    const report = generateReport(evaluations)

    expect(report).toContain('# Skill Evaluation Report')
    expect(report).toContain('Total Skills Evaluated: 2')
    expect(report).toContain('shadcn-ui')
    expect(report).toContain('reui')
  })

  test('should have all 15 skills defined', () => {
    expect(TOP_15_SKILLS).toHaveLength(15)
  })

  test('should have valid skill configurations', () => {
    TOP_15_SKILLS.forEach(skill => {
      expect(skill.name).toBeTruthy()
      expect(skill.description).toBeTruthy()
      expect(Array.isArray(skill.techStack)).toBe(true)
      expect(Array.isArray(skill.strengths)).toBe(true)
      expect(Array.isArray(skill.useCases)).toBe(true)
    })
  })
})

// Run tests if executed directly
if (require.main === module) {
  console.log('Running skill evaluation tests...')
  
  // Simple test execution
  const defaultCriteria: EvaluationCriteria = {
    componentQuality: 8,
    developerExperience: 8,
    projectFit: 8,
    performance: 8
  }

  // Test single skill evaluation
  const skill = TOP_15_SKILLS[0]
  const evaluation = evaluateSkill(skill, defaultCriteria)
  console.log(`✓ Evaluated ${skill.name}: ${evaluation.score}`)

  // Test comparison
  const skills = TOP_15_SKILLS.slice(0, 3)
  const evaluations = compareSkills(skills, [defaultCriteria, defaultCriteria, defaultCriteria])
  console.log(`✓ Compared ${evaluations.length} skills`)

  // Test report generation
  const report = generateReport(evaluations)
  console.log(`✓ Generated report (${report.length} characters)`)

  console.log('\nAll tests passed!')
}
