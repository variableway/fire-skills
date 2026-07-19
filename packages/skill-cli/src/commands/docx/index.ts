import { convertDocxToMarkdown } from "@skill-spark/tool-docx";

export interface DocxToMdOptions {
  source: string;
  output: string;
}

export async function runDocxToMd(options: DocxToMdOptions): Promise<void> {
  const result = await convertDocxToMarkdown(options.source, options.output);

  if (!result.success) {
    console.error(`Error: ${result.error}`);
    process.exit(1);
  }

  console.log(`Converted: ${options.source} → ${result.outputPath}`);
}
