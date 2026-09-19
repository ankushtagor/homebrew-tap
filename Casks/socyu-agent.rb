cask "socyu-agent" do
  version "0.1.4"

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
  on_arm do
    sha256 "d93cabe1c9f7c3f617e23f42ffbc3a715bc720ad0e8afb6886ceca831f90a975"
    url "https://github.com/ankushtagor/socyu-agent-releases/releases/download/v#{version}/SocyU.Agent-#{version}-arm64.dmg",
        verified: "github.com/ankushtagor/socyu-agent-releases/"
  end
  on_intel do
    sha256 "399ca6764082182576d7946288d64fe7d691ccf919d0ab18e88aea836b9561e3"
    url "https://github.com/ankushtagor/socyu-agent-releases/releases/download/v#{version}/SocyU.Agent-#{version}.dmg",
        verified: "github.com/ankushtagor/socyu-agent-releases/"
  end

  name "SocyU Agent"
  desc "SocyU on-device content agent"
  homepage "https://socyu.app"

  depends_on macos: ">= :sonoma"

  app "SocyU Agent.app"

  # Ad-hoc signed, unnotarized (no paid Apple Developer Program — see
  # sdk/socyu-agent/docs/TERMINAL_INSTALL_PLAN.md "Zero-cost constraint").
  # Homebrew has already verified this download's sha256 against the value
  # pinned above before this line runs, so clearing quarantine here is
  # backed by that independent integrity check — do not replicate this in
  # a standalone curl script without the same verify-first ordering.
  postflight do
    system_command "/usr/bin/xattr",
                    args: ["-dr", "com.apple.quarantine", "#{appdir}/SocyU Agent.app"],
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
