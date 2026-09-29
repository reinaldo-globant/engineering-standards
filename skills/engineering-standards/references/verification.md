# Verification Before Completion

**Iron law: NO COMPLETION CLAIM WITHOUT FRESH EVIDENCE.**

If you have not run the verification command in this session, after the last change, you cannot
claim it passes.

## The gate

Before stating any status — or expressing satisfaction:

1. **Identify** the command that proves the claim.
2. **Run** it, fresh and complete. Not a subset, not a cached result.
3. **Read** the full output. Check the exit code. Count the failures.
4. **Compare** the output to the claim.
   - Doesn't confirm it → state the actual status, with the evidence.
   - Confirms it → state the claim, with the evidence.
5. **Only then** say it.

Skipping a step is not verifying, it is asserting.

## What each claim requires

| Claim | Requires | Not sufficient |
|---|---|---|
| Tests pass | Test command output, 0 failures | A previous run, "should pass" |
| Linter clean | Linter output, 0 errors | A partial check, extrapolation |
| Build succeeds | Build command, exit 0 | Linter passing, "logs look fine" |
| Bug fixed | The original symptom retested, passing | Code changed, assumed fixed |
| Regression test works | Failed before the fix, passes after | Passes once, after the fix |
| Subagent completed | The diff shows the changes | The agent reported success |
| Requirements met | Line-by-line pass over the request | The test suite is green |
| Deployed | The service answering, on the new version | The pipeline turned green |
| Anything, on data you altered | The alteration stated alongside the claim | A green run against rows you inserted or reset |

## Red flags — stop and run the command

"should", "probably", "seems to" · declaring victory before running anything · about to commit,
push, or open a PR unverified · trusting a subagent's success report · partial verification
extrapolated to the whole · "just this once" · being tired and wanting the task over · any wording
that implies success without evidence behind it.

## Provenance of evidence

Evidence is only evidence if you did not manufacture it. A suite that passes against rows you
inserted, a store you reset, or a fixture you rewrote proves that you can write rows. It does not
prove the code works.

When verification touched the data in any way, the claim carries that fact: what you changed, when,
and why. A success report that omits it is not an optimistic summary, it is a false one — and
unlike a wrong number, the reader has no way to detect the substitution afterwards. That
undetectability is what makes it the most damaging failure in this document.

If the honest report is "I could not verify this without altering the data," then that is the
report. Say it and stop.

## Reporting honestly

Failures are reported with the output, not summarized away. A skipped step is stated as skipped.
Work blocked partway is reported as blocked, with everything that *was* finished listed explicitly
— scaling the task down is the user's call, not yours. When something is done and verified, say it
plainly, without hedging.
