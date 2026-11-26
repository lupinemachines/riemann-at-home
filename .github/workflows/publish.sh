#!/bin/sh
# Copies each proof's newest build record to <run id>/<proof>.json on this repo's `records` branch, so a build's
# progress can be read (and posted to Riemann@home) from outside while the job runs, and survives a lost runner.
for p in 17m 300k; do
  d="$HOME/.riemann-at-home"
  if [ "$p" = 300k ]; then d="$d/300k"; fi
  r=$(ls "$d"/records/*.json 2>/dev/null | tail -1)
  if [ -z "$r" ]; then continue; fi
  api="$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/contents/$GITHUB_RUN_ID/$p.json"
  sha=$(curl -fsS -H "Authorization: Bearer $REPO_TOKEN" "$api?ref=records" 2>/dev/null | jq -r '.sha // empty')
  base64 -w0 "$r" > "$RUNNER_TEMP/record.b64"
  jq -n --rawfile c "$RUNNER_TEMP/record.b64" --arg s "$sha" --arg m "$p record of run $GITHUB_RUN_ID" \
      '{message: $m, branch: "records", content: $c} + (if $s == "" then {} else {sha: $s} end)' |
    curl -fsS -X PUT -H "Authorization: Bearer $REPO_TOKEN" -d @- "$api" >/dev/null \
    && echo "published $p record $(basename "$r")" || echo "could not publish the $p record"
done
