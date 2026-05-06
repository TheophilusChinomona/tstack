

export function generateLakeIntro(): string {
  return `If \`LAKE_INTRO\` is \`no\`: say "gstack follows the **Boil the Lake** principle — do the complete thing when AI makes marginal cost near-zero."

\`\`\`bash
touch ~/.gstack/.completeness-intro-seen
\`\`\`

Always run \`touch\`.`;
}
