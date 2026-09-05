'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const { verifyReleaseEvidence } = require('./release_evidence.cjs');

const sha = 'a'.repeat(40);
const repo = { owner: 'xelis-project', repo: 'xelis-wallet-flutter' };

function fixture() {
  const runs = ['pull-request.yml', 'consumer-validation.yml'].map((workflow, index) => ({
    workflow, id: index + 1, head_sha: sha, event: 'workflow_dispatch',
    head_repository: { full_name: `${repo.owner}/${repo.repo}` },
    status: 'completed', conclusion: 'success', run_attempt: 1,
    html_url: `https://github.com/example/actions/runs/${index + 1}`,
  }));
  const jobs = [['validate'], ['linux', 'windows', 'macos', 'android', 'ios', 'web']]
    .map(names => names.map(name => ({ name, head_sha: sha, status: 'completed', conclusion: 'success' })));
  const state = { runs, jobs, changed: false, apiFailure: false };
  const github = {
    rest: { actions: {
      listWorkflowRuns: 'runs', listJobsForWorkflowRun: 'jobs',
      getWorkflowRun: async ({ run_id }) => ({ data: {
        ...runs.find(run => run.id === run_id),
        run_attempt: state.changed ? 2 : 1,
      } }),
    } },
    paginate: async (method, parameters) => {
      if (state.apiFailure) throw new Error('API unavailable');
      assert.equal(parameters.per_page, 100);
      if (method === 'runs') {
        assert.equal(parameters.head_sha, sha);
        assert.equal(parameters.event, 'workflow_dispatch');
        return runs.filter(run => run.workflow === parameters.workflow_id);
      }
      assert.equal(parameters.filter, 'latest');
      return jobs[parameters.run_id - 1];
    },
  };
  return { state, github, repo, sha };
}

test('accepts both exact-SHA manual validations and all six successful jobs', async () => {
  assert.equal((await verifyReleaseEvidence(fixture())).length, 2);
});

const rejectedCases = {
  'invalid SHA': input => { input.sha = 'main'; },
  'missing run': ({ state }) => { state.runs.pop(); },
  'different commit': ({ state }) => { state.runs[1].head_sha = 'b'.repeat(40); },
  'pull request run': ({ state }) => { state.runs[0].event = 'pull_request'; },
  'foreign repository': ({ state }) => { state.runs[1].head_repository.full_name = 'other/fork'; },
  'failed run': ({ state }) => { state.runs[1].conclusion = 'failure'; },
  'running validation': ({ state }) => { state.runs[1].status = 'in_progress'; },
  'missing platform': ({ state }) => { state.jobs[1].pop(); },
  'skipped platform in targeted run': ({ state }) => { state.jobs[1][0].conclusion = 'skipped'; },
  'failed platform': ({ state }) => { state.jobs[1][0].conclusion = 'failure'; },
  'cancelled platform': ({ state }) => { state.jobs[1][0].conclusion = 'cancelled'; },
  'job on other SHA': ({ state }) => { state.jobs[1][0].head_sha = 'b'.repeat(40); },
  'duplicate job': ({ state }) => { state.jobs[1].push({ ...state.jobs[1][0] }); },
  'new failure after older success': ({ state }) => {
    state.runs.push({ ...state.runs[1], id: 3, conclusion: 'failure' });
  },
  'rerun during inspection': ({ state }) => { state.changed = true; },
  'API failure': ({ state }) => { state.apiFailure = true; },
};
for (const [name, mutate] of Object.entries(rejectedCases)) {
  test(`rejects ${name}`, async () => {
    const input = fixture();
    mutate(input);
    await assert.rejects(verifyReleaseEvidence(input));
  });
}

test('workflow job identifiers stay aligned with the evidence checker', () => {
  const general = readFileSync(resolve(__dirname, '../../.github/workflows/pull-request.yml'), 'utf8');
  const consumers = readFileSync(resolve(__dirname, '../../.github/workflows/consumer-validation.yml'), 'utf8');
  assert.match(general, /^  validate:$/m);
  for (const name of ['linux', 'windows', 'macos', 'android', 'ios', 'web']) {
    assert.match(consumers, new RegExp(`^  ${name}:$`, 'm'));
    assert.ok(consumers.includes(`if: inputs.platform == 'all' || inputs.platform == '${name}'`));
  }
  assert.doesNotMatch(consumers, /^  push:$/m);
  assert.match(consumers, /^  workflow_dispatch:$/m);
});

test('tag gate stays read-only and does not set up wallet build toolchains', () => {
  const gate = readFileSync(resolve(__dirname, '../../.github/workflows/release-validation.yml'), 'utf8');
  assert.match(gate, /^  push:$/m);
  assert.match(gate, /^  workflow_dispatch:$/m);
  assert.match(gate, /^  actions: read$/m);
  assert.match(gate, /^  contents: read$/m);
  assert.doesNotMatch(gate, /: write\b|flutter-action|rust-cache|consumer_smoke|cargo /);
  assert.ok(gate.includes('git rev-parse HEAD^{commit}'));
});
