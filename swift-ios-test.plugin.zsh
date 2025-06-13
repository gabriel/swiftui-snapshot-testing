# To install:
#
# mkdir -p ~/.oh-my-zsh/custom/plugins/swift-ios-test
# cp swift-ios-test.plugin.zsh ~/.oh-my-zsh/custom/plugins/swift-ios-test/swift-ios-test.plugin.zsh
#
# # Add swift-ios-test to .zshrc
# plugins=(git swift-ios-test ...)
#
# source ~/.zshrc

swift() {
  if [[ "$1" == "test" && " ${@} " =~ " --ios " ]]; then
    # Extract target name from Package.swift
    scheme=$(
      grep -A 2 "\.library(" Package.swift \
        | grep "name:" \
        | sed 's/.*name: "\(.*\)".*/\1/'
    )

    # find the latest iPhone device name
    device=${SWIFT_IOS_TEST_DEVICE_NAME:-$(
      xcrun simctl list devices available \
        | grep -oE 'iPhone [0-9]+' \
        | sort -V \
        | tail -n1
    )}

    # find the latest iOS runtime
    os=${SWIFT_IOS_TEST_OS:-$(
      xcrun simctl list runtimes \
        | grep -Eo 'iOS [0-9]+\.[0-9]+' \
        | sed 's/iOS //' \
        | sort -V \
        | tail -n1
    )}

    local -a xcodebuild_cmd=(
      "xcodebuild" "test"
      "-scheme" "$scheme"
      "-destination" "platform=iOS Simulator,name=$device,OS=$os"
    )

    # This doesn't really work with SPM packages
    local -a args=("$@")
    local filter_index=${args[(i)--filter]}
    if (( filter_index <= ${#args} )); then
      local filter_value=${args[filter_index+1]}
      if [[ -n "$filter_value" ]]; then
        xcodebuild_cmd+=("-only-testing:${filter_value}")
      fi
    fi

    "${xcodebuild_cmd[@]}"
  else
    command swift "$@"
  fi
}