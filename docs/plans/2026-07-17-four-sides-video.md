# Four-Sides Video Implementation Plan

> **For Codex:** Follow `superpowers:test-driven-development` and verify each behavior before completion.

**Goal:** Add a reusable FFmpeg CLI that places one duplicated video or four separate videos on the four sides of a square canvas without overlap.

**Architecture:** A standalone Bash script validates arguments, probes input durations, builds one FFmpeg filter graph, and selects codecs by output format. Integration tests generate deterministic source videos with FFmpeg and inspect the exported files with ffprobe and pixel sampling.

**Tech Stack:** Bash, FFmpeg, ffprobe, awk.

**CLI Contract:** Show help and exit successfully when called without arguments. Otherwise accept exactly one input or four inputs ordered as top, right, bottom, and left. Defaults are a 1080x1080 black canvas, 30 percent square slots, no margin, 30 fps, `contain` fitting, inward rotation, and MP4 output when no format can be inferred. When `--output` is omitted, create `<stem>_four_sides_YYYYMMDD_HHMMSS_<pid>.<format>` beside the first input. An extensionless `--output result` creates `result.mp4`; an explicit `--format` selects the appended extension instead. Supported formats are MP4 and MOV with H.264, plus WebM with VP9. Output is silent and stops at the shortest input duration.

**Auto Crop:** `--auto-crop` compares pixels with `--background` in RGB color space, then detects and removes the matching solid-color outer rectangle before slot scaling. RGB comparison avoids treating bright neutral subjects, such as white jade on black, as background. Analyze the complete video at 2 fps and merge all detected foreground boxes, including positions reached later in the video. Parse only `Parsed_bbox` filter log lines so filenames or unrelated logs containing crop-like text cannot affect the result. Odd source dimensions remain valid. `--crop-threshold` defaults to `0.08` and accepts values from `0.00001` to `1`. `--crop-padding-percent` accepts integers from 0 to 100 and defaults to 10; larger values retain more background and make the subject smaller inside its slot. Cropping enlarges a small foreground without changing slot placement or the non-overlap bound. It does not make retained background pixels transparent.

**Auto-Crop Cost:** Auto-crop fully decodes each source once for boundary analysis, then decodes it again for final composition. Long videos have an additional analysis delay before output encoding begins.

**Layout Rule:** Reject a layout when `3 × element_size + 2 × margin > canvas_size`. Equality is allowed because adjacent square slots only touch at their edges.

---

### CLI contract and test harness

**Files:**

- Create: `utilities/shell/video/tests/test_four_sides_video.sh`
- Create: `utilities/shell/video/four_sides_video.sh`

Write failing help and argument-validation tests, including a no-argument call that prints help successfully. Run the tests and confirm the command is missing. Add the smallest script entry point with English usage text, dependency checks, input-count validation, and safe output handling. Run the tests again.

### Single-input composition

**Files:**

- Modify: `utilities/shell/video/tests/test_four_sides_video.sh`
- Modify: `utilities/shell/video/four_sides_video.sh`

Add a failing integration test that generates one asymmetric sample video, exports a square MP4, and checks its resolution, H.264 codec, background, inward rotations, four occupied edge regions, and empty center. Implement input splitting, inward rotations, contain/cover scaling, square slots, overlay placement, and H.264 output. Add separate tests that confirm `cover` fills the full square slot, `--auto-crop` removes a solid-color border with configurable padding, a white foreground on black remains intact under RGB comparison, later moving positions remain inside the combined boundary, odd source dimensions export successfully, unrelated crop text is ignored, and thresholds below `0.00001` are rejected. Enforce `3 × element_size + 2 × margin <= canvas_size` so video boxes cannot overlap.

### Four-input composition and formats

**Files:**

- Modify: `utilities/shell/video/tests/test_four_sides_video.sh`
- Modify: `utilities/shell/video/four_sides_video.sh`

Add a four-input test with separately colored videos. Check top, right, bottom, and left assignment, a solid center background, shortest-input duration, `--orientation none`, and WebM output with the VP9 codec. Add separate checks for MOV output, extensionless output defaulting to MP4, timestamped default output naming, overlap rejection, overwrite protection, and rejection when the output refers to any input file.

### Documentation and verification

**Files:**

- Modify: `utilities/shell/README.md`
- Modify: `utilities/README.md`

Document requirements, input ordering, defaults, supported formats, non-overlap limits, RGB automatic cropping and its extra decode pass, a recommended jade-bird asset example, and the solid-background constraint. The final integration suite contains 21 tests. Run these commands from the repository root, run ShellCheck when available, and inspect the final diff without staging or committing files:

```bash
bash -n utilities/shell/video/four_sides_video.sh
bash -n utilities/shell/video/tests/test_four_sides_video.sh
bash utilities/shell/video/tests/test_four_sides_video.sh
```
