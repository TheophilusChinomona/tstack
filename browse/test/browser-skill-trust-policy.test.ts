import { describe, it, expect, beforeEach, afterEach } from 'bun:test';
import {
  buildSpawnEnv,
} from '../src/browser-skill-commands';

describe('buildSpawnEnv — trust policy regression gates', () => {
  let origEnv: Record<string, string | undefined>;
  beforeEach(() => {
    origEnv = { ...process.env };
    process.env.GITHUB_TOKEN = 'gh-secret';
    process.env.OPENAI_API_KEY = 'oai-secret';
    process.env.MY_PASSWORD = 'sup3r';
    process.env.NPM_TOKEN = 'npmtok';
    process.env.AWS_SECRET_ACCESS_KEY = 'aws-secret';
    process.env.GSTACK_TOKEN = 'root-token';
    process.env.HOME = '/Users/test';
    process.env.PATH = '/test/bin:/usr/bin';
    process.env.LANG = 'en_US.UTF-8';
  });
  afterEach(() => {
    for (const k of Object.keys(process.env)) {
      if (!(k in origEnv)) delete process.env[k];
    }
    for (const [k, v] of Object.entries(origEnv)) {
      if (v !== undefined) process.env[k] = v;
    }
  });

  it('frontmatter trusted:true without operator grant → scrubbed env', () => {
    const env = buildSpawnEnv({ trusted: true, operatorTrustGranted: false, port: 1234, skillToken: 'tok' });
    expect(env.HOME).toBeUndefined();
    expect(env.GITHUB_TOKEN).toBeUndefined();
    expect(env.OPENAI_API_KEY).toBeUndefined();
    expect(env.PATH).not.toContain('/test/bin');
  });

  it('frontmatter trusted:true without operator grant (default) → scrubbed env', () => {
    const env = buildSpawnEnv({ trusted: true, port: 1234, skillToken: 'tok' });
    expect(env.HOME).toBeUndefined();
    expect(env.GITHUB_TOKEN).toBeUndefined();
  });

  it('frontmatter trusted:false with operator grant → still scrubbed', () => {
    const env = buildSpawnEnv({ trusted: false, operatorTrustGranted: true, port: 1234, skillToken: 'tok' });
    expect(env.HOME).toBeUndefined();
    expect(env.GITHUB_TOKEN).toBeUndefined();
  });

  it('untrusted: child never sees GSTACK_TOKEN even if parent has it', () => {
    const env = buildSpawnEnv({ trusted: false, port: 1234, skillToken: 'tok' });
    expect(env.GSTACK_TOKEN).toBeUndefined();
  });

  it('untrusted: child never sees provider/cloud/SSH keys', () => {
    process.env.ANTHROPIC_API_KEY = 'anthropic-secret';
    process.env.GOOGLE_APPLICATION_CREDENTIALS = '/path/to/creds.json';
    process.env.SSH_PRIVATE_KEY = 'ssh-secret';
    const env = buildSpawnEnv({ trusted: false, port: 1234, skillToken: 'tok' });
    expect(env.ANTHROPIC_API_KEY).toBeUndefined();
    expect(env.GOOGLE_APPLICATION_CREDENTIALS).toBeUndefined();
    expect(env.SSH_PRIVATE_KEY).toBeUndefined();
  });

  it('trusted + operator grant → keeps $HOME and developer secrets', () => {
    const env = buildSpawnEnv({ trusted: true, operatorTrustGranted: true, port: 1234, skillToken: 'tok' });
    expect(env.HOME).toBe('/Users/test');
    expect(env.GITHUB_TOKEN).toBe('gh-secret');
  });

  it('trusted + operator grant → still strips GSTACK_TOKEN (defense in depth)', () => {
    const env = buildSpawnEnv({ trusted: true, operatorTrustGranted: true, port: 1234, skillToken: 'tok' });
    expect(env.GSTACK_TOKEN).toBeUndefined();
  });

  it('GSTACK_PORT/GSTACK_SKILL_TOKEN can never be overridden by parent env (trusted + grant)', () => {
    process.env.GSTACK_PORT = '99999';
    process.env.GSTACK_SKILL_TOKEN = 'attacker-tok';
    const env = buildSpawnEnv({ trusted: true, operatorTrustGranted: true, port: 1234, skillToken: 'real-tok' });
    expect(env.GSTACK_PORT).toBe('1234');
    expect(env.GSTACK_SKILL_TOKEN).toBe('real-tok');
  });
});
