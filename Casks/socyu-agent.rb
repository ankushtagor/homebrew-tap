cask "socyu-agent" do
  version "0.1.2"

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
  on_arm do
    sha256 "3d4789329339d46fde53ef3553fbe4c6af84a50a6fc341bb06718c654551f18d"
    url "https://github.com/ankushtagor/socyu-agent-releases/releases/download/v#{version}/SocyU.Agent-#{version}-arm64.dmg",
        verified: "github.com/ankushtagor/socyu-agent-releases/"
  end
  on_intel do
    sha256 "220476c1e240a1e275fdb23b192b19b4221e7e1cf45d0679241fd8570de5f379"
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
