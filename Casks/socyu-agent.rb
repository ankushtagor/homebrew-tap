cask "socyu-agent" do
  version "0.1.1"

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
  on_arm do
    sha256 "2208d46e6af1da2676a8a3c5f14ce270516308db186fa35aa485cd6f9c76f8f1"
    url "https://github.com/ankushtagor/socyu-agent-releases/releases/download/v#{version}/SocyU.Agent-#{version}-arm64.dmg",
        verified: "github.com/ankushtagor/socyu-agent-releases/"
  end
  on_intel do
    sha256 "1574222357c3b1a6f0309e367f16327f722d7d304757d14c509d523c2dff9b9a"
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
