# A08 Optimization Mindset

Goal: understand what production-ready usually means beyond visual quality.

Production-ready often means:
- predictable data flow
- no accidental per-frame allocations
- stable render path
- reusable systems
- readable ownership of game vs renderer responsibility

## Things To Watch

1. per-frame allocations
2. rebuilding heavy data unnecessarily
3. effect systems with no pooling
4. random renderer changes for one-off gimmicks
5. too many special cases in shader paths

## Practice

- identify one place where particle pooling matters
- identify one place where a new renderer feature would be overkill
- identify one place where a renderer feature is actually justified
