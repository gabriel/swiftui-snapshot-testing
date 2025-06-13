# To install:
#
# mkdir -p ~/.oh-my-zsh/custom/plugins/swift-ios-test
# cp swift-ios-test.plugin.zsh ~/.oh-my-zsh/custom/plugins/swift-ios-test/swift-ios-test.plugin.zsh
#
# # Add swift-ios-test to .zshrc
# plugins=(git swift-ios-test ...)
#
# source ~/.zshrc


cat << 'EOF' > ~/.oh-my-zsh/custom/plugins/swift-ios-test/swift-ios-test.plugin.zsh
# Override `swift test --ios`
swift() {
  if [[ "$1" == "test" && "$2" == "--ios" ]]; then
    # Extract target name from Package.swift
    scheme=$(
      grep -A 2 "\.library(" Package.swift \
        | grep "name:" \
        | sed 's/.*name: "\(.*\)".*/\1/'
    )

    # find the latest iPhone device name
    device=$(
      xcrun simctl list devices available \
        | grep -oE 'iPhone [0-9]+' \
        | sort -V \
        | tail -n1
    )

    # find the latest iOS runtime
    os=$(
      xcrun simctl list runtimes \
        | grep -Eo 'iOS [0-9]+\.[0-9]+' \
        | sed 's/iOS //' \
        | sort -V \
        | tail -n1
    )

    xcodebuild test \
      -scheme "$scheme" \
      -destination "platform=iOS Simulator,name=$device,OS=$os"
  else
    command swift "$@"
  fi
}
EOF
