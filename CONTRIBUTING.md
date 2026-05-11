# Contributing

Thanks for taking a look. Speedread is a small side project, so reviews and releases happen when I have a free evening — but contributions are welcome and I'll do my best to engage with anything thoughtful.

## A good fit

- Bug fixes — especially anything that crashes, breaks the trigger, or trips up the selection grab.
- Small UX improvements (a screenshot or short clip of the before/after is always nice).
- New tests that cover a real failure mode.
- macOS compatibility fixes for newer releases.

## Worth a chat first

For anything bigger — new reading modes, new third-party dependencies, broad refactors, or anything that meaningfully grows the surface area — please open an issue before writing the code. A quick conversation up front saves both of us time and helps make sure the change has somewhere to land.

## Local setup

```sh
brew install xcodegen
xcodegen generate
open Speedread.xcodeproj
```

Run the tests in Xcode (`⌘U`) or from the terminal:

```sh
xcodebuild test \
  -project Speedread.xcodeproj \
  -scheme Speedread \
  -destination 'platform=macOS'
```

## Pull requests

- Keep PRs small and focused — several small PRs are easier to review than one large one.
- Match the surrounding code style; there's no enforced formatter.
- Include a brief note on what changed and why.

## Releases

Tagging is handled by the maintainer — pushing a `v*` tag triggers `.github/workflows/release.yml`, which builds the DMG and updates the marketing site. You don't need to bump versions in a PR.

## Licence

By contributing you agree your contribution is released under the [MIT licence](LICENSE).
