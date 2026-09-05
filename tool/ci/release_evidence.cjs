'use strict';

const requirements = Object.freeze([
  { workflow: 'pull-request.yml', jobs: ['validate'] },
  {
    workflow: 'consumer-validation.yml',
    jobs: ['linux', 'windows', 'macos', 'android', 'ios', 'web'],
  },
]);

// Require the newest manual run, not an older green result hidden by a failure.
// Manual validation also guarantees that the general workflow runs Rust tests.
async function verifyReleaseEvidence({ github, repo, sha }) {
  if (!/^[a-f0-9]{40}$/.test(sha ?? '')) {
    throw new Error('Expected an exact candidate commit SHA.');
  }
  const evidence = [];
  for (const requirement of requirements) {
    const runs = await github.paginate(github.rest.actions.listWorkflowRuns, {
      ...repo,
      workflow_id: requirement.workflow,
      head_sha: sha,
      event: 'workflow_dispatch',
      per_page: 100,
    });
    const run = runs
      .filter(item => item.head_sha === sha &&
        item.event === 'workflow_dispatch' &&
        item.head_repository?.full_name === `${repo.owner}/${repo.repo}`)
      .sort((left, right) => right.id - left.id)[0];
    if (!run || run.status !== 'completed' || run.conclusion !== 'success') {
      throw new Error(`${requirement.workflow}: newest manual run for ${sha} must be completed successfully.`);
    }
    const jobs = await github.paginate(github.rest.actions.listJobsForWorkflowRun, {
      ...repo,
      run_id: run.id,
      filter: 'latest',
      per_page: 100,
    });
    for (const name of requirement.jobs) {
      const matches = jobs.filter(job => job.name === name);
      if (matches.length !== 1 || matches[0].head_sha !== sha ||
          matches[0].status !== 'completed' || matches[0].conclusion !== 'success') {
        throw new Error(`${requirement.workflow}: job ${name} must succeed for ${sha}; missing, skipped or ambiguous jobs are not evidence.`);
      }
    }
    // Fail closed if a rerun started while its jobs were being inspected.
    const { data: current } = await github.rest.actions.getWorkflowRun({
      ...repo,
      run_id: run.id,
    });
    if (current.head_sha !== sha || current.run_attempt !== run.run_attempt ||
        current.status !== 'completed' || current.conclusion !== 'success') {
      throw new Error(`${requirement.workflow}: run changed during verification; retry after it completes.`);
    }
    evidence.push({ workflow: requirement.workflow, url: run.html_url });
  }
  return evidence;
}

module.exports = { verifyReleaseEvidence };
