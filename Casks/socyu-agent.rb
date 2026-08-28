cask "socyu-agent" do
  version "0.1.0"

  # TODO(deploy step 3 in RUNBOOK.md): replace OWNER/REPO once the release
  # repo exists. These two file names match what `npm run dist:dev:arm64`
  # and `npm run dist:dev:x64` already produce byte-for-byte — do not rename
  # on upload, or the sha256 pins below go stale.
  on_arm do
    sha256 "eb730dc4439627bec608a20081e3dd449ba7e90039dc43c4f37fa5b1a4a4654c"
    url "https://github.com/ankushtagor/socyu-agent-releases/releases/download/v#{version}/SocyU Agent-#{version}-arm64.dmg",
        verified: "github.com/ankushtagor/socyu-agent-releases/"
  end
  on_intel do
    sha256 "4203cf3d599f17e8854851091d41ace421442d940405d55aa5120484db8d84b4"
    url "https://github.com/ankushtagor/socyu-agent-releases/releases/download/v#{version}/SocyU Agent-#{version}.dmg",
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
