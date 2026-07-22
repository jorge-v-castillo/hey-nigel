#!/usr/bin/env python3
"""Exports XCTAttachment screenshots (and other file attachments) from an
.xcresult bundle produced by `xcodebuild test`.

Xcode 16's `xcresulttool get test-results` subcommands (summary, tests,
test-details, activities, insights, metrics) don't expose raw attachment
files directly, so this walks the older `--legacy` JSON object graph instead:
actions -> testsRef -> ActionTestPlanRunSummaries -> testableSummaries ->
tests (recursing into subtests) -> summaryRef -> activitySummaries (recursing
into subactivities) -> attachments -> payloadRef.id, which is then exported
via `xcresulttool export object --legacy --type file`.
"""
import json
import os
import subprocess
import sys

BUNDLE = sys.argv[1] if len(sys.argv) > 1 else "TestResults.xcresult"
OUT_DIR = sys.argv[2] if len(sys.argv) > 2 else "screenshots"


def get_object(object_id=None):
    cmd = ["xcrun", "xcresulttool", "get", "--legacy", "--format", "json", "--path", BUNDLE]
    if object_id:
        cmd += ["--id", object_id]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"xcresulttool get failed for id={object_id}: {result.stderr}", file=sys.stderr)
        return {}
    stdout = result.stdout
    # Defensive: skip any stray non-JSON lines (e.g. deprecation notices) before the object.
    brace = stdout.find("{")
    if brace == -1:
        return {}
    return json.loads(stdout[brace:])


def export_file(object_id, output_path):
    subprocess.run(
        [
            "xcrun", "xcresulttool", "export", "object", "--legacy",
            "--type", "file", "--id", object_id, "--path", BUNDLE, "--output-path", output_path,
        ],
        check=True,
    )


def values(node, key):
    return (node or {}).get(key, {}).get("_values", [])


def ref_id(node, key):
    return (((node or {}).get(key) or {}).get("id") or {}).get("_value")


attachments_found = []


def walk_activities(activities):
    for activity in activities:
        for attachment in values(activity, "attachments"):
            name = (attachment.get("name") or {}).get("_value") or f"attachment-{len(attachments_found)}"
            payload_id = ref_id(attachment, "payloadRef")
            if payload_id:
                attachments_found.append((name, payload_id))
        walk_activities(values(activity, "subactivities"))


def walk_tests(tests):
    for test in tests:
        subtests = values(test, "subtests")
        if subtests:
            walk_tests(subtests)
        summary_id = ref_id(test, "summaryRef")
        if summary_id:
            test_summary = get_object(summary_id)
            walk_activities(values(test_summary, "activitySummaries"))


os.makedirs(OUT_DIR, exist_ok=True)
root = get_object()

for action in values(root, "actions"):
    tests_ref_id = ref_id(action.get("actionResult"), "testsRef")
    if not tests_ref_id:
        continue
    test_plan_summaries = get_object(tests_ref_id)
    for summary in values(test_plan_summaries, "summaries"):
        for testable in values(summary, "testableSummaries"):
            walk_tests(values(testable, "tests"))

for index, (name, payload_id) in enumerate(attachments_found):
    safe_name = "".join(c if c.isalnum() or c in "-_." else "_" for c in name)
    out_path = os.path.join(OUT_DIR, f"{index:02d}-{safe_name}.png")
    export_file(payload_id, out_path)
    print(f"Exported {out_path}")

print(f"Total attachments exported: {len(attachments_found)}")
