import { z } from "zod";

export const SkillNameSchema = z
  .string()
  .trim()
  .min(1, "Skill name is required")
  .max(64, "Skill name must be at most 64 characters")
  .regex(/^(?!-)(?!.*--)[a-z0-9-]+(?<!-)$/i, "Skill name must be kebab-case letters, numbers, and hyphens");

export const SkillFrontmatterSchema = z
  .object({
    name: SkillNameSchema.optional(),
    description: z.string().trim().min(1, "Skill description is required").optional(),
  })
  .passthrough();

export const RequiredSkillFrontmatterSchema = SkillFrontmatterSchema.extend({
  name: SkillNameSchema,
  description: z.string().trim().min(1, "Skill description is required"),
});

export const SourceRefSchema = z.object({
  kind: z.enum(["local", "git", "well-known", "directory", "registry"]),
  input: z.string().min(1),
  label: z.string().min(1).optional(),
  url: z.string().min(1).optional(),
  branch: z.string().min(1).optional(),
  subpath: z.string().min(1).optional(),
});

export const ValidationIssueSchema = z.object({
  severity: z.enum(["error", "warning", "info"]),
  code: z.string().min(1),
  message: z.string().min(1),
  file: z.string().optional(),
  path: z.string().optional(),
});

export const ValidationReportSchema = z.object({
  path: z.string().min(1),
  name: z.string().optional(),
  description: z.string().optional(),
  status: z.enum(["valid", "warning", "invalid"]),
  issues: z.array(ValidationIssueSchema),
});

export const RiskSignalSchema = z.object({
  level: z.enum(["low", "medium", "high", "critical"]),
  code: z.string().min(1),
  message: z.string().min(1),
  file: z.string().optional(),
});

export const InspectionReportSchema = z.object({
  path: z.string().min(1),
  name: z.string().optional(),
  description: z.string().optional(),
  riskLevel: z.enum(["low", "medium", "high", "critical"]),
  qualityScore: z.number().min(0).max(100),
  portabilityScore: z.number().min(0).max(100),
  validation: ValidationReportSchema,
  riskSignals: z.array(RiskSignalSchema),
  summary: z.object({
    hasFrontmatter: z.boolean(),
    hasScripts: z.boolean(),
    hasReferences: z.boolean(),
    scriptCount: z.number().int().nonnegative(),
    referenceCount: z.number().int().nonnegative(),
    assetCount: z.number().int().nonnegative(),
    lineCount: z.number().int().nonnegative(),
  }),
});

export const SkillProfileSchema = z.object({
  name: SkillNameSchema,
  description: z.string().optional(),
  skills: z.array(
    z.object({
      name: SkillNameSchema,
      source: z.string().min(1),
      version: z.string().optional(),
    }),
  ),
  targetAgents: z.array(z.string()).default([]),
});

export const SkillRunSessionSchema = z.object({
  sessionId: z.string().min(1),
  objective: z.string().min(1),
  selectedSkills: z.array(
    z.object({
      name: SkillNameSchema,
      source: z.string().min(1),
      path: z.string().optional(),
    }),
  ),
  provider: z.enum(["manual", "host-codex", "host-claude", "mastra", "n8n", "dify"]),
  status: z.enum(["draft", "ready", "running", "needs_approval", "done", "failed"]),
  artifacts: z.array(z.string()).default([]),
  logs: z.array(z.string()).default([]),
});

export type SkillFrontmatter = z.infer<typeof SkillFrontmatterSchema>;
export type ValidationIssue = z.infer<typeof ValidationIssueSchema>;
export type ValidationReport = z.infer<typeof ValidationReportSchema>;
export type RiskSignal = z.infer<typeof RiskSignalSchema>;
export type InspectionReport = z.infer<typeof InspectionReportSchema>;
export type SkillProfile = z.infer<typeof SkillProfileSchema>;
export type SkillRunSession = z.infer<typeof SkillRunSessionSchema>;
