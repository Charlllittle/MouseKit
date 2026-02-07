fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Push a new beta build to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Push a new release build to App Store

### ios build

```sh
[bundle exec] fastlane ios build
```

Build the app without uploading

### ios build_for_test_all

```sh
[bundle exec] fastlane ios build_for_test_all
```

Build for testing (all tests)

### ios test_all_only

```sh
[bundle exec] fastlane ios test_all_only
```

Run all the tests (without building)

### ios test_all

```sh
[bundle exec] fastlane ios test_all
```

Run all the tests (build + test)

### ios bump_patch

```sh
[bundle exec] fastlane ios bump_patch
```

Bump patch version (e.g., 1.0.0 -> 1.0.1) and commit

### ios bump_minor

```sh
[bundle exec] fastlane ios bump_minor
```

Bump minor version (e.g., 1.0.0 -> 1.1.0) and commit

### ios bump_major

```sh
[bundle exec] fastlane ios bump_major
```

Bump major version (e.g., 1.0 -> 2.0) and commit

### ios set_version

```sh
[bundle exec] fastlane ios set_version
```

Bump the version number and commit

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
