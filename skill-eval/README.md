# Skill Evaluation Directory

This directory contains research and evaluation materials for frontend development skills, based on the innate-base template project.

## Contents

### 1. Frontend Skill Evaluation (`frontend-skill-eval.md`)
- Top 15 recommended frontend development skills
- Evaluation criteria and scoring system
- Recommended skill combinations for different use cases

### 2. Innate Frontend Starter Skill (`innate-frontend-starter.md`)
- Preliminary skill based on Top 15 Skills and innate-base
- Complete setup instructions for Next.js and TanStack Router
- Component library integration guide
- Project structure and conventions

### 3. Project Constraints Methods (`project-constraints.md`)
- Technical constraints (framework, styling, UI components)
- Architecture constraints (project structure, naming conventions)
- Component creation rules and patterns
- Theme system requirements
- Performance and security constraints
- First version documentation and checklist

### 4. Skill Evaluation Code (`skill-eval.ts`)
- TypeScript implementation of skill evaluation system
- Weighted scoring algorithm (component quality, developer experience, project fit, performance)
- Report generation functionality
- Exportable functions for external use

### 5. Skill Evaluation Tests (`skill-eval.test.ts`)
- Unit tests for the evaluation system
- Test cases for scoring, comparison, and report generation
- Simple test runner for validation

## Usage

### Running the Evaluation

```bash
# Run the evaluation system
npx ts-node skill-eval.ts

# Or compile and run
tsc skill-eval.ts
node skill-eval.js
```

### Running Tests

```bash
# Run tests
npx ts-node skill-eval.test.ts

# Or with Jest (if configured)
npm test
```

### Using in Projects

```typescript
import { evaluateSkill, TOP_15_SKILLS } from './skill-eval'

// Evaluate a specific skill
const evaluation = evaluateSkill(TOP_15_SKILLS[0], {
  componentQuality: 8,
  developerExperience: 8,
  projectFit: 8,
  performance: 8
})

console.log(evaluation.score)
console.log(evaluation.recommendations)
```

## Evaluation Criteria

### 1. Component Quality (30%)
- Accessibility (WCAG compliance)
- TypeScript support
- Customization flexibility
- Documentation quality

### 2. Developer Experience (30%)
- Setup complexity
- Learning curve
- Community support
- Maintenance status

### 3. Project Fit (25%)
- Compatibility with innate-base
- Integration with @innate/ui
- Support for admin/dashboard patterns
- Theme system compatibility

### 4. Performance (15%)
- Bundle size
- Rendering performance
- SSR/SSG support

## Next Steps

1. Integrate evaluation system into skill development workflow
2. Add more detailed scoring criteria
3. Create automated testing for skill quality
4. Develop skill recommendation engine
