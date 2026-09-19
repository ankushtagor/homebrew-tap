cask "socyu-agent" do
  version "0.1.6"

  # GitHub Releases renames spaces in uploaded asset filenames to dots
  # (confirmed via `gh release view --json assets` after the real upload —
  # "SocyU Agent-0.1.0-arm64.dmg" landed as "SocyU.Agent-0.1.0-arm64.dmg").
  # Match that exactly, not the local dist/ filename or a %20-encoded one —
  # both of those 404.
  #
  # v0.1.1 fixes two real bugs found testing against a second machine:
  #  1. Unpaired devices had no way to reach the UI if the menu-bar tray
  #     icon didn't render (confirmed happening on macOS 26.0) — the
  #     dashboard now auto-opens on first launch while unpaired
  #     (firstLaunchDashboard.js).
  #  2. The DMG was shipping every OS/arch's ffprobe-static and
  #     onnxruntime-node binaries at once (~270MB of dead weight on a mac
  #     build) — after-pack.js now prunes to just the target platform/arch,
  #     cutting the DMG from ~452MB to ~338MB.
  #
  # v0.1.2: Kokoro TTS segment caching (media/ttsCache.js) + profile-aware
  # speech delivery strategy (media/speechDeliveryStrategy.js) — reduces
  # repeat-synthesis time and personalizes narration pacing/gesture pattern
  # from the business profile.
  #
  # v0.1.3: Sarvam Hindi TTS provider (alternate to AWS Polly), Market Lens
  # service refactor + IPC module, article-grounded trend-carousel writer,
  # draft retention, and content pipeline fixes.
  #
  # v0.1.4: maximum asar compression + explicit unpack of ffmpeg-static /
  # ffprobe-static / onnxruntime-node (previously duplicated inside app.asar
  # since only *.node matched the unpack glob). ~357MB -> ~334MB, no
  # functional change. Verified via codesign --verify --deep --strict on
  # both arches, a DMG mount/contents check, and npm run test:media before
  # this release was cut.
  #
  # v0.1.5: fixes a real production bug — resolveApiBase.js's "probe
  # localhost:8000, fall back to prod" dev convenience had no packaged-build
  # gate, so any unrelated service already listening on port 8000 on a
  # user's machine silently hijacked every API call for the life of the
  # process (reported as "Check now" throwing a raw Flask/Werkzeug 404 page
  # instead of this app's real JSON error shape). Now gated on
  # app.isPackaged. Also: tray icon sometimes invisible on a cold launch
  # (trayVisibilityFix.js watchdog), Business info tab blank on first open.
  #
  # v0.1.6: fixes the app freezing ("Not Responding", up to 30s) on launch —
  # the ffmpeg license audit ran spawnSync twice on the main thread, on
  # every launch, each with a 15s timeout. Especially bad the first time a
  # machine ever runs the bundled (unsigned, ad-hoc-signed) ffmpeg binary,
  # since macOS Gatekeeper's first-run scan adds real latency before it can
  # even execute. Now async and cached — never blocks startup, and only the
  # very first launch on a machine spawns ffmpeg for this at all.
  on_arm do
    sha256 "7680d268557b851c259e797aad62b537b5ac70bd28604bef4c453d02570b222d"
    url "https://github.com/ankushtagor/socyu-agent-releases/releases/download/v#{version}/SocyU.Agent-#{version}-arm64.dmg"
  end
  on_intel do
    sha256 "f2db0a5ddca4b29f0b116c30565f83cc0f738674ca4b452f7eda0cda1e489f16"
    url "https://github.com/ankushtagor/socyu-agent-releases/releases/download/v#{version}/SocyU.Agent-#{version}.dmg"
  end

  name "SocyU Agent"
  desc "SocyU on-device content agent"
  homepage "https://socyu.app"

  depends_on macos: :sonoma

  app "SocyU Agent.app"

  # Ad-hoc signed, unnotarized (no paid Apple Developer Program — see
  # sdk/socyu-agent/docs/TERMINAL_INSTALL_PLAN.md "Zero-cost constraint").
  # Homebrew has already verified this download's sha256 against the value
  # pinned above before this line runs, so clearing quarantine here is
  # backed by that independent integrity check — do not replicate this in
  # a standalone curl script without the same verify-first ordering.
  #
  # postflight_steps runs in a different DSL than the old postflight block —
  # it builds a declarative, JSON-serialisable step list (Homebrew::InstallSteps::DSL,
  # see install_steps.rb in a brew checkout), not plain Ruby. Two real
  # consequences, both confirmed by reading that source directly:
  #   1. The method is `run`, not `system_command` — `system_command` doesn't
  #      exist in this DSL at all.
  #   2. `appdir` is not a callable Ruby method here (undef_method strips
  #      almost everything from this class), so `"#{appdir}/..."` throws
  #      "undefined local variable or method 'appdir'". Path tokens are
  #      resolved later, at run time, by substring-matching literal
  #      `{{appdir}}` in the arg string (Runner#expand_template_tokens) — so
  #      it has to be written as a template token, not interpolated.
  postflight_steps do
    run "/usr/bin/xattr",
        args: ["-dr", "com.apple.quarantine", "{{appdir}}/SocyU Agent.app"],
        sudo: false
  end

  caveats <<~EOS
    SocyU Agent is not notarized by Apple (no paid Developer Program).
    Homebrew already cleared the quarantine flag that would otherwise
    block first launch, so `open -a "SocyU Agent"` should just work.
    If macOS still refuses to open it: System Settings -> Privacy &
    Security -> scroll to the blocked-app notice -> "Open Anyway".
  EOS

  zap trash: [
    "~/Library/Application Support/SocyU Agent",
    "~/Library/Caches/com.socyu.agent",
    "~/Library/Saved Application State/com.socyu.agent.savedState",
  ]
end
