import { readFileSync, writeFileSync } from "node:fs";
import mammoth from "mammoth";

export interface DocxToMdResult {
  success: boolean;
  outputPath: string;
  error?: string;
}

/**
 * Convert a .docx file to Markdown.
 * @param sourcePath - Path to the source .docx file.
 * @param targetPath - Path where the output .md file should be written.
 * @returns Result indicating success/failure and the output path.
 */
export async function convertDocxToMarkdown(
  sourcePath: string,
  targetPath: string,
): Promise<DocxToMdResult> {
  try {
    const buffer = readFileSync(sourcePath);

    const result = await mammoth.convertToMarkdown(
      { buffer },
      {
        // Include default style mappings for better output
        styleMap: [
          "p[style-name='Heading 1'] => h1",
          "p[style-name='Heading 2'] => h2",
          "p[style-name='Heading 3'] => h3",
          "p[style-name='Heading 4'] => h4",
          "p[style-name='Heading 5'] => h5",
          "p[style-name='Heading 6'] => h6",
          "p[style-name='Quote'] => blockquote",
          "r[style-name='Strong'] => strong",
          "r[style-name='Emphasis'] => em",
          "p[style-name='List Bullet'] => ul > li",
          "p[style-name='List Number'] => ol > li",
        ].join("\n"),
      },
    );

    if (result.messages.length > 0) {
      console.warn("Conversion warnings:");
      for (const msg of result.messages) {
        console.warn(`  [${msg.type}] ${msg.message}`);
      }
    }

    writeFileSync(targetPath, result.value, "utf-8");

    return {
      success: true,
      outputPath: targetPath,
    };
  } catch (error) {
    return {
      success: false,
      outputPath: targetPath,
      error: error instanceof Error ? error.message : "Unknown error during conversion",
    };
  }
}
