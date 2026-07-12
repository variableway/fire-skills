export function normalizedFormat(
  format: string | undefined,
  output?: string,
): string {
  if (format) {
    if (!["text", "json", "markdown", "md"].includes(format)) {
      throw new Error(`Unsupported format: ${format}`);
    }
    return format === "md" ? "markdown" : format;
  }
  if (output?.endsWith(".json")) return "json";
  if (output?.endsWith(".md") || output?.endsWith(".markdown")) return "markdown";
  return "text";
}
