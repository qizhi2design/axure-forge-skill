import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { copyFileSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const binary = resolve(process.argv[2] || '');
assert.ok(process.argv[2], 'Usage: node tests/templates.mjs BINARY [--strict] [--report FILE]');
const strict = process.argv.includes('--strict');
const reportAt = process.argv.indexOf('--report');
const assets = join(repo, 'skills/axure-forge/assets/html-templates');
const manifest = JSON.parse(readFileSync(join(assets, 'manifest.json'), 'utf8'));
const temp = mkdtempSync(join(tmpdir(), 'axure-html-templates-'));
const results = [];
try {
  for (const template of manifest.templates) {
    const html = join(temp, `${template.id}.html`);
    copyFileSync(join(assets, template.file), html);
    const call = spawnSync(binary, ['html', 'import', html,
      '--page-size', template.suggested_page_size, '--page-mode', template.page_mode,
      '--output', join(temp, `${template.id}.rp`), '--work-dir', join(temp, template.id),
      '--verify', '--fail-on', strict ? 'warn' : 'error'],
    { cwd: temp, encoding: 'utf8', timeout: 120000 });
    assert.equal(call.status, 0, `${template.id}: ${call.stderr}\n${call.stdout}`);
    const data = JSON.parse(call.stdout);
    assert.deepEqual(data.result.warnings, [], `${template.id}: unsupported HTML/CSS`);
    const summary = data.evidence;
    const [width, minHeight] = template.suggested_page_size.split('x').map(Number);
    assert.equal(summary.canvas.width, width);
    assert.ok(summary.canvas.height >= minHeight);
    assert.equal(summary.counts.pages, 1);
    assert.ok(summary.counts.nodes > 0);
    const report = JSON.parse(readFileSync(summary.report, 'utf8'));
    assert.equal(report.counts.error, 0);
    if (strict) assert.equal(report.counts.warn, 0);
    assert.equal(report.verification.visual, 'not_checked');
    results.push({ template: template.id, canvas: summary.canvas,
      nodes: summary.counts.nodes, findings: report.counts,
      unsupported: data.result.warnings, visual: 'not_checked', interaction: 'not_checked' });
  }
  const report = { strict, passed: true, templates: results };
  if (reportAt >= 0) {
    assert.ok(process.argv[reportAt + 1], '--report needs a file path');
    writeFileSync(resolve(process.argv[reportAt + 1]), JSON.stringify(report, null, 2) + '\n');
  }
  console.log(JSON.stringify(report, null, 2));
} finally {
  rmSync(temp, { recursive: true, force: true });
}
