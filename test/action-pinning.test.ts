import { describe, it, expect } from 'bun:test';
import { readFileSync, readdirSync } from 'fs';
import { join } from 'path';

describe('GitHub Actions supply-chain security', () => {
  const workflowsDir = join(import.meta.dir, '..', '.github', 'workflows');
  const workflowFiles = readdirSync(workflowsDir).filter(f => f.endsWith('.yml'));

  it('every workflow file exists', () => {
    expect(workflowFiles.length).toBeGreaterThan(0);
  });

  for (const file of workflowFiles) {
    it(`${file}: all third-party actions are pinned to a 40-char commit SHA`, () => {
      const content = readFileSync(join(workflowsDir, file), 'utf-8');
      const lines = content.split('\n');
      for (const line of lines) {
        const lineWithoutComment = line.split('#')[0].trim();
        const match = lineWithoutComment.match(/uses: [^@/]+\/[^@/]+@([0-9a-f]{40})$/);
        if (match) {
          expect(match[1].length).toBe(40);
        }
        const mutableMatch = lineWithoutComment.match(/uses: [^@/]+\/[^@/]+@v\d/);
        expect(mutableMatch, `Action in ${file} must not use mutable tag: ${lineWithoutComment}`).toBeNull();
      }
    });
  }

  it('pr-title-sync.yml has an immutable checkout reference', () => {
    const content = readFileSync(join(workflowsDir, 'pr-title-sync.yml'), 'utf-8');
    expect(content).toMatch(/actions\/checkout@[0-9a-f]{40}/);
    expect(content).not.toMatch(/actions\/checkout@v\d/);
  });
});
