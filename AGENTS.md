# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-openscap` is a SIMP Puppet module that installs the OpenSCAP tooling and
SCAP content, and optionally schedules recurring SCAP scans via cron. It installs
the `openscap-utils` and `scap-security-guide` packages, and — when scheduling is
enabled — writes a `/var/log/openscap` log directory and a `cron` job that runs
`oscap xccdf eval` against a chosen SSG data stream and profile, optionally
rotating the resulting logs with `logrotate`.

The module ships a custom `oscap` fact (`lib/facter/oscap.rb`) that discovers the
`oscap` binary, its version, supported specifications, and the SCAP profiles
available on the target under `/usr/share/xml/scap/*/content/*-ds.xml`. The
schedule class uses that fact to validate that the requested data stream and
profile actually exist before installing the cron job (`manifests/schedule.pp`).

### Business logic

Two classes (`openscap`, `openscap::schedule`) and one type alias
(`Openscap::Profile`). Neither class is `assert_private()`'d — both are public
and consumers `include` them directly.

- **`openscap` (`manifests/init.pp`)** — Public entry class. Calls
  `simplib::assert_metadata($module_name)` (`init.pp`). Parameters:
  - `$enable_schedule` (`Boolean`, default `false`) — when true, `include`s
    `openscap::schedule` and orders `Class['openscap'] -> Class['openscap::schedule']`
    (`init.pp`).
  - `$scap_ensure` (`String`) — ensure for `openscap-utils`; defaults to
    `simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' })`
    (`init.pp`).
  - `$ssg_ensure` (`String`) — ensure for `scap-security-guide`; same
    `simp_options::package_ensure` default (`init.pp`).
  - Declares `package { 'openscap-utils' }` and `package { 'scap-security-guide' }`
    (`init.pp`).

- **`openscap::schedule` (`manifests/schedule.pp`)** — Public class that
  sets up the recurring scan. `include`s `openscap` (`schedule.pp`). Key
  parameters:
  - `$scap_profile` (`Openscap::Profile`, **required, no default**) — the SSG
    profile id (`schedule.pp`).
  - `$ssg_data_stream` (`Pattern[/^.+\.xml$/]`, **required, no default**) — the
    data stream XML filename under `$ssg_base_dir` (`schedule.pp`).
  - `$oscap_path` (`Stdlib::Absolutepath`) — `pick(fact('oscap.path'), '/bin/oscap')`,
    i.e. the path from the `oscap` fact, falling back to `/bin/oscap`
    (`schedule.pp`).
  - `$ssg_base_dir` (`Stdlib::Absolutepath`, default
    `/usr/share/xml/scap/ssg/content`) (`schedule.pp`).
  - `$fetch_remote_resources` (`Boolean`, default `false`) (`schedule.pp`).
  - `$scap_tailoring_file` (`Optional[Stdlib::Absolutepath]`, default `undef`)
    (`schedule.pp`).
  - `$logdir` (`Stdlib::Absolutepath`, default `/var/log/openscap`) (`schedule.pp`).
  - `$logrotate` (`Boolean`) — defaults to
    `simplib::lookup('simp_options::logrotate', { 'default_value' => false })`
    (`schedule.pp`).
  - `$minute`/`$hour`/`$monthday`/`$month`/`$weekday` — cron schedule, typed with
    `Simplib::Cron::*`, defaulting to `30`/`1`/`*`/`*`/`1` (`schedule.pp`).
  - `$force` (`Boolean`, default `false`) — bypass the fact-based validation and
    install the schedule anyway (`schedule.pp`).

  Control flow (`schedule.pp`):
  - If `$force`, `$_set_schedule = true` unconditionally (`schedule.pp`).
  - Otherwise, when the `oscap` fact is present, it walks
    `$facts['oscap']['profiles'][$ssg_base_dir][<data-stream basename>][$scap_profile]`
    and `fail()`s with a specific message at each missing level — no profiles, no
    data streams under the base dir, missing data stream, missing profile
    (`schedule.pp`).
  - When the `oscap` fact is absent, it emits a `notify` at `warning` loglevel and
    sets `$_set_schedule = false` — the schedule is silently skipped
    (`schedule.pp`).
  - When `$_set_schedule`, it declares `file { $logdir }` (`ensure => directory`,
    `mode => '0600'`) and `cron { 'openscap' }` whose command is rendered from
    `templates/oscap_command.erb` (`schedule.pp`).
  - If `$logrotate`, `include`s `logrotate` and declares a
    `logrotate::rule { 'openscap' }` rotating `${logdir}/*.xml` daily, keeping 3
    (`schedule.pp`).

- **`Openscap::Profile` (`types/profile.pp`)** — `Pattern[/xccdf_[^_]+_profile_.+/]`;
  constrains `$scap_profile` to a valid SSG profile id shape.

- **`oscap` fact (`lib/facter/oscap.rb`)** — `confine`d to hosts where `oscap` is
  on the PATH and at least one `*-ds.xml` exists under `/usr/share/xml/scap/*/content/`
  (`oscap.rb`). Returns a hash of `path`, `version`, `supported_specifications`,
  and a nested `profiles` map keyed by directory → data stream → profile id
  (`oscap.rb`). It parses data-stream XML with a regex scan rather than a
  full XML parse for speed, keeping only `xccdf_org.ssg*` profile ids
  (`oscap.rb`).

- **`templates/oscap_command.erb`** — builds the `oscap xccdf eval` command line:
  `--profile`, timestamped `--results`/`--report` files under `$logdir`, optional
  `--tailoring-file` and `--fetch-remote_resources`, ending with
  `${ssg_base_dir}/${ssg_data_stream}`.

### Gotchas / non-obvious details

- **The schedule is silently skipped when `oscap` is not installed.** Without
  `$force`, if the `oscap` fact is absent no cron job is created — only a
  `warning` notify is emitted (`schedule.pp`). The fact itself is `confine`d
  to hosts that already have `oscap` on the PATH *and* SSG data streams present
  (`oscap.rb`), so on a first run before the packages are installed the fact
  will not exist. Use `$force` to install the schedule regardless
  (`schedule.pp`).
- **Profile/data-stream validation happens at catalog-compile time** against the
  compiling node's `oscap` fact, and `fail()`s the catalog with a precise message
  if the requested data stream or profile is missing (`schedule.pp`). This
  means the data stream and profile must actually exist on the node.
- **`$scap_profile` is validated by a type pattern**, not a free string:
  `Openscap::Profile = Pattern[/xccdf_[^_]+_profile_.+/]` (`types/profile.pp`).
- **`$ssg_data_stream` must end in `.xml`** (`Pattern[/^.+\.xml$/]`,
  `schedule.pp`); the fact keys data streams by their `.xml`-stripped basename,
  and `schedule.pp` strips it via `basename($ssg_data_stream, '.xml')`
  (`schedule.pp`).
- **`simp/simp_options` is NOT a declared dependency** in `metadata.json`, yet
  both manifests consume the `simp_options::*` seam via `simplib::lookup`
  (provided by `simp/simplib`). `simp_options` does not even appear as a fixture
  in `.fixtures.yml`.
- **Default SSG profile/data stream come from module data, not manifest defaults.**
  `$scap_profile` and `$ssg_data_stream` are required parameters with no manifest
  default; per-OS values are supplied from `data/os/*.yaml` (e.g. RedHat-8 →
  `ospp` profile + `ssg-rhel8-ds.xml`; RedHat-7 → `standard` + `ssg-rhel7-ds.xml`).
- **The cron log directory is mode `0600`** (`schedule.pp`) and results are
  written as timestamped `.xml`/`.html` files, which is what the optional
  `logrotate::rule` targets (`${logdir}/*.xml`).
- **`logrotate` is a hard `metadata.json` dependency** but is only `include`d when
  `$logrotate` is true (`schedule.pp`); the `simp_options::logrotate`
  lookup defaults it to `false` (`schedule.pp`).
- **The ERB emits `--fetch-remote_resources`** (with an underscore) rather than
  the documented `--fetch-remote-resources`; verify against the target `oscap`
  version before relying on remote-resource fetching (`templates/oscap_command.erb`).

## The `simp_options` / `simplib::lookup` seam

All `simp_options::*` lookups (the natural target for lookup-path unit tests):

| File | Key | `default_value` |
|------|-----|-----------------|
| `manifests/init.pp` | `simp_options::package_ensure` | `'installed'` |
| `manifests/init.pp` | `simp_options::package_ensure` | `'installed'` |
| `manifests/schedule.pp` | `simp_options::logrotate` | `false` |

Keep routing SIMP feature toggles through `simplib::lookup('simp_options::*', {
'default_value' => ... })` with an explicit default rather than assuming
`simp_options` is included.

## Dependencies

Module dependencies (from `metadata.json`):

- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0` (provides `Stdlib::Absolutepath`,
  `pick()`, `basename()`)
- `simp/simplib` `>= 4.9.0 < 5.0.0` (provides `simplib::lookup`,
  `simplib::assert_metadata`, and the `Simplib::Cron::*` types)
- `simp/logrotate` `>= 6.5.0 < 7.0.0` (provides `logrotate::rule`; only used when
  `$logrotate` is true)

There is no `simp.optional_dependencies` key in `metadata.json`.

Fixture-only dependencies (from `.fixtures.yml`, present for test compilation, not
runtime deps): `cron_core` (`puppetlabs/cron_core`, provides the `cron` type). The
three runtime deps above are also checked out as fixtures. Note `simp_options` is
**not** present as a fixture even though the manifests reference the seam.

Runtime requirement (from `metadata.json` `requirements`): `puppet >= 7.0.0 < 9.0.0`.
(SIMP is migrating Puppet → OpenVox; when `metadata.json` switches this to
`openvox`, update this line to match.)

Supported OS matrix (from `metadata.json`): CentOS 7/8/9; RedHat 7/8/9;
OracleLinux 7/8/9; Rocky 8/9; AlmaLinux 8/9.

## Repository layout

- `manifests/init.pp` — the `openscap` class (package installs + optional schedule).
- `manifests/schedule.pp` — the `openscap::schedule` class (cron scan + validation
  + optional logrotate).
- `types/profile.pp` — the `Openscap::Profile` type alias.
- `lib/facter/oscap.rb` — the custom `oscap` fact (binary path, version, supported
  specs, available profiles).
- `templates/oscap_command.erb` — builds the `oscap xccdf eval` cron command.
- `data/os/*.yaml` — per-OS `openscap::schedule::scap_profile` and
  `openscap::schedule::ssg_data_stream` defaults; `hiera.yaml` is a v5 hierarchy
  (OS+Release → OS → Kernel → common). There is no `data/common.yaml`.
- `metadata.json` — deps, OS matrix, Puppet requirement (no optional deps).
- `spec/classes/init_spec.rb`, `spec/classes/schedule_spec.rb` — rspec-puppet unit
  tests. `spec/type_aliases/openscap_profile_spec.rb` — type-alias tests.
  `spec/unit/facter/oscap_spec.rb` — fact tests. Sample SSG content under
  `spec/fixtures/ssg_samples/`.
- `spec/acceptance/suites/default/` — beaker acceptance suites
  (`00_default_spec.rb`, `10_with_a_schedule_spec.rb`); nodesets under
  `spec/acceptance/nodesets/` (`default.yml`, `oel.yml`, `rocky.yml`).
- `REFERENCE.md` — generated Puppet Strings reference.
- **Acceptance is NOT wired into CI.** `.github/workflows/pr_tests.yml` runs only
  syntax, style/lint, rubocop, file checks, RELENG checks, and a `spec-tests`
  matrix (Puppet 7.x on Ruby 2.7, Puppet 8.x on Ruby 3.2). There is no
  `acceptance` job; the beaker suites must be run manually.

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Run a single spec
bundle exec rspec spec/classes/schedule_spec.rb

# Puppet lint
bundle exec rake lint

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run the default beaker acceptance suite (not run in CI)
bundle exec rake beaker:suites[default]
```

Relevant gem pins (from `Gemfile`): `puppetlabs_spec_helper ~> 8.0.0`,
`simp-rake-helpers ~> 5.24.0`, `simp-rspec-puppet-facts ~> 4.0.0`,
`simp-beaker-helpers ~> 2.0.0`. Rubocop is pinned to `~> 1.88.0`. The tested
Puppet range is `>= 7 < 9`. `spec/spec_helper.rb` uses
`require 'puppetlabs_spec_helper/module_spec_helper'` (not the voxpupuli helper).

## Conventions

- Preserve the puppet-strings docstrings on the classes and parameters — they
  drive `REFERENCE.md`. Regenerate `REFERENCE.md` after changing docs or parameters.
- Keep per-OS SCAP defaults (`scap_profile`, `ssg_data_stream`) in `data/os/*.yaml`,
  not hard-coded in the manifests.
- Continue routing SIMP feature toggles through
  `simplib::lookup('simp_options::*', { 'default_value' => ... })` rather than
  assuming `simp_options` is included.
- Guard the schedule with the `oscap`-fact validation (or `$force`) as
  `schedule.pp` does — don't install a cron scan for a profile/data stream that
  doesn't exist on the node.
- `Gemfile`, `spec/spec_helper.rb`, and `.github/workflows/pr_tests.yml` carry a
  **puppetsync** notice — they are baseline-managed and the next sync overwrites
  local edits. Push changes to those files upstream to the baseline, not here.
- Match the existing 2-space Puppet indentation and aligned-arrow parameter style
  used in the manifests.
