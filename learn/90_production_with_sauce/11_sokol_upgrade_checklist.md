# Sokol Upgrade Checklist

Use this later when you decide to refresh vendored Sokol fully.

## Upgrade Goal

Make these agree with each other:
- `sauce/sokol/c/*.h`
- `sauce/sokol/*.odin` generated bindings
- `sokol-shdc-*` tool version
- `sauce/generated_shader.odin` output

If these drift apart, shader/build pain returns.

## When To Upgrade

Good time:
- after vertical slice
- before lots of shader/post-process work
- when branch is calm

Bad time:
- mid feature rush
- before demo deadline
- while debugging gameplay bugs

## Checklist

1. Create branch
`upgrade/sokol-refresh`

2. Record current versions
- Odin version
- current Sokol header snapshot
- current `sokol-shdc` binary version

3. Update vendored C headers
- `sauce/sokol/c/sokol_*.h`

4. Regenerate Odin bindings
- app
- gfx
- glue
- log
- gl
- shape
- debugtext
- time
- audio if used

5. Rebuild static libs
- mac
- windows
- linux

6. Regenerate shaders
- `sauce/generated_shader.odin`

7. Compile and fix API changes
- shader desc fields
- pipeline config
- bindings arrays
- app/environment glue

8. Run game and test
- window boots
- sprites draw
- text draws
- sound loads
- input works
- no shader errors

9. Remove temporary compatibility normalization if no longer needed

10. Update docs
- build commands
- learning docs

## Verify Points

Must verify these after upgrade:
- `./build_mac.sh`
- `odin run ./sauce/build`
- explicit shader regen build
- run game from build output

## Minimal Success Definition

Upgrade is done only when:
1. build succeeds
2. game runs
3. regenerated shaders compile without compatibility hacks
4. renderer matches previous behavior
