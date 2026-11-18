# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.x     | :white_check_mark: |
| 1.x     | :x:                |
| < 1.0   | :x:                |

## Scope

This project is a **terminal banner renderer**. It only reads your own
configuration and prints ASCII art to your terminal.

It does **not** run anything as root, it does not download code at runtime and
it does not send any telemetry. The only network access happens when *you*
explicitly enable the `ip` dashboard widget on a system where the address has
to be resolved remotely.

## What the installer touches

| Path                            | What happens                          |
| ------------------------------- | ------------------------------------- |
| `$PREFIX/etc/bash.bashrc`       | a marked block is added (never overwritten) |
| `$PREFIX/etc/zshrc`             | a marked block is added (never overwritten) |
| `~/.termux-banner/config`       | your settings (mode `600`)            |
| `~/.termux-banner/boot.sh`      | the startup hook (mode `700`)         |
| `$PREFIX/bin/tb`                | the command line entry point          |
| `<rc file>.tbbak`               | a backup of your rc file              |

`bash remove.sh` reverts every one of these changes.

## Reporting a Vulnerability

Please report security issues privately instead of opening a public issue:

* GitHub Security Advisories — https://github.com/Faizee-Asad/Termux-Banner/security/advisories/new
* Twitter — [@faizee_asad](https://twitter.com/faizee_asad)

Include a description of the issue, the steps to reproduce it, the output of
`tb --doctor` and, if possible, a minimal example.

You can expect an acknowledgement within a few days. If the report is valid, a
fix is released as a new patch version and the advisory is published with full
credit to the reporter.

## Sandboxing your own install

If you want to be extra careful while trying the project out:

```bash
cp -r Termux-Banner /tmp/tb-test
cd /tmp/tb-test
bash install.sh          # writes only inside $HOME and $PREFIX
bash remove.sh --purge   # removes everything it added
```
