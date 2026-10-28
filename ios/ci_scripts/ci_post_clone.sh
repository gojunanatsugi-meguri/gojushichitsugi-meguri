#!/bin/sh
# Xcode Cloud がリポジトリをクローンした直後に実行するスクリプト。
# Xcode Cloud には Flutter が入っていないので、ここで入れて、iOS のビルドに必要なファイルを作る
set -e

cd "$CI_PRIMARY_REPOSITORY_PATH"

# 手元の開発環境と同じバージョンの Flutter を使う
git clone https://github.com/flutter/flutter.git --depth 1 -b 3.47.5 "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter precache --ios
flutter pub get

# TestFlight は同じビルド番号を2回受け付けないので、Xcode Cloud のビルド番号（毎回増える）を使う
flutter build ios --config-only --release --no-codesign --build-number="$CI_BUILD_NUMBER"
