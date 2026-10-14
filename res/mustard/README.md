# Mustard desktop builds

The `mustard-build.yml` workflow builds both Windows architectures (x64 and ARM64),
both macOS architectures (Intel and Apple Silicon), and both Linux architectures
(x64 and ARM64), with Debian/RPM and AppImage packages. Select one edition per run.
Two separate runs keep the helper, bridge and package artifacts isolated.
Mustard runs upload build artifacts and do not publish GitHub releases.

Configure `RENDEZVOUS_SERVER`, `RS_PUB_KEY`, and optionally `MUSTARD_RELAY_SERVER`
as repository Actions secrets. Their values come from the private mustard-infra
configuration. No server values are committed here.

Two editions share the same code and artwork:

* `support`: **Mustard Support**, using RustDesk's existing incoming-only mode.
* `remote`: **Mustard Remote**, with normal incoming and outgoing capabilities.

Internal app, bundle, service and installed executable names are `MustardSupport`
and `MustardRemote`: the existing privileged installer scripts require names
without spaces. The desktop UI displays the names above.

No edition selected means the existing RustDesk configuration and UI path.
Mustard editions use their own app name, configuration directory and service identity.
They do not load the vendor-signed `custom.txt` profile. Existing RustDesk settings
are not migrated. Upstream update checks are already disabled for custom app names;
distribute Mustard updates through mustard-infra.

## Build preparation

Use a separate, clean checkout for each edition. Supply `RENDEZVOUS_SERVER` and
`RS_PUB_KEY` through the private build environment. Optionally supply
`MUSTARD_RELAY_SERVER` and `API_SERVER`. Only public server configuration belongs
in these variables; do not supply server private keys or credentials.

On a configured build machine, wrap the usual native build command:

```sh
python res/mustard/prepare.py --edition support -- python build.py --flutter
python res/mustard/prepare.py --edition remote -- python build.py --flutter
```

Run each command in its own checkout. The wrapper installs the branded image assets,
updates platform product metadata, and sets `MUSTARD_EDITION` for the build command.
The Rust compiler embeds the server configuration and edition. Server options supplied
here override saved settings. Rebuild the Rust library for each edition; do not use
`--skip-cargo` with a library from a different edition.

To stage artwork without building:

```sh
python res/mustard/prepare.py --edition support --prepare-only
```

When building staged files manually, set `MUSTARD_EDITION=support` or `remote` in
the Rust build environment as well. No Flutter Rust Bridge codegen is needed for
these changes; the normal build still needs the project's existing generated bridge.

Windows release packaging must use the edition's name for installer/product metadata
and the installed executable. The existing MSI tool accepts
`--app-name MustardSupport --conn-type incoming --manufacturer Mustard` or
`--app-name MustardRemote --manufacturer Mustard`. Internal build
outputs may still be named `rustdesk`; the connection settings do not depend on
the download filename. Signing, installer generation and publication remain the
responsibility of the release pipeline.

The wrapper selects the host desktop platform automatically; `--platform windows`,
`--platform macos`, or `--platform linux` can stage files for another build runner.
macOS uses a branded bundle name, edition-specific bundle identifier, and ICNS icon.
Linux keeps the existing `rustdesk` package/executable/service names, with branded
desktop entries and icons. The two editions therefore cannot be installed side by
side using the existing Linux packages.

## Windows privacy screen

The client-facing screen says **Support session in progress**, with a request to
leave the computer on and the office number **07 855 6424**. It does not describe
the session as hidden or display a privacy-status badge.

The privacy window is rendered by **WindowInjection.dll**, from the separately
built RustDeskTempTopMostWindow project. For a local helper build, check out the
same pinned commit used by `third-party-RustDeskTempTopMostWindow.yml`, then run:

```sh
python res/mustard/prepare.py --privacy-source /path/to/RustDeskTempTopMostWindow
```

This replaces only the helper's embedded image source. Build the helper with its
normal MSBuild command, and include that DLL in **both** edition bundles before
signing and creating the portable installer. For the reusable helper workflow,
pass `mustard-branding: true`; existing callers default to the stock image.
Keep the generated helper source with the release's corresponding source materials.

`mustard-windows-package.yml` can refresh Windows packages without rebuilding the
client or codec dependencies. It takes a desktop build run ID, verifies its edition,
downloads that run's compiled Windows bundles, rebuilds only the image helper and
portable wrapper, and produces named MSI/EXE files plus `SHA256SUMS`. Its initial
push-triggered package branches reference the two desktop runs from this change;
for subsequent releases use the workflow's explicit `source-run-id` input.

The artwork applies to Windows privacy modes that use the topmost window helper.
Virtual-display modes and macOS display blanking do not show this image. No privacy
or capture logic has changed. Incoming-only mode retains upstream's verified
switch-sides exception; it is not a strict ban on all outgoing network traffic
or an authorization policy for incoming technicians.

## Atera deployment

Use the **MustardSupport** MSI for customer machines. Atera supports uploading an
MSI to Scripts, with `/qn` arguments and **Run as System**. Use the package matching
the device's x64 or ARM64 architecture. Both editions include MSI installers;
the staff package is **MustardRemote**.

For a hosted download or when the MSI exceeds the Atera upload limit, use
`Install-MustardSupport.ps1` as a System script. Provide the HTTPS URL of the chosen
Support MSI and its SHA-256 from the same release's `SHA256SUMS`:

```powershell
.\Install-MustardSupport.ps1 -MsiUri 'https://your-download-host/MustardSupport-x86_64.msi' -Sha256 '<64-character-release-sha256>'
```

The script requires administrator privileges, checks the download hash, installs
with `/qn /norestart`, and writes the installer log under `ProgramData\Mustard\Logs`.
It does not deploy through Atera by itself. Publish the selected MSI to your download
host or upload it in Atera before rollout. It neither removes AnyDesk/other RustDesk
installations nor sets a shared unattended-access password.

[Atera's MSI/script deployment instructions](https://support.atera.com/hc/en-us/articles/235215188-Create-upload-and-generate-scripts).

## Connection direction and source IP

Incoming-only mode governs remote-session initiation. A working session exchanges
network traffic in both directions, and clients establish connections to the ID/relay
server. An endpoint firewall sees the relay address for relayed sessions, so a firewall
rule alone cannot distinguish a staff controller from another controller behind that
relay. The relay service also accepts customer connections; restricting its entire
port to the office IP would block those customers.

This checkout's existing `whitelist` option checks the session's peer address before
login, including the address passed through the relay path. A fixed office or VPN
exit IP can be allowlisted there; keep password/user approval as well. A roaming
technician needs a known exit IP to use an IP restriction consistently. No source-IP
restriction has been applied yet: the permitted staff addresses are still required.

[RustDesk's IP allowlist reference](https://rustdesk.com/docs/en/self-host/client-configuration/advanced-settings/#whitelist).

## Artwork

The mark, palette and Zain fonts come from the Mustard website repository.
The fonts retain their SIL Open Font License in `OFL.txt`. The committed images
allow build preparation with Python alone. To regenerate them, install ImageMagick
and run `python res/mustard/generate.py`. `privacy.png` is also a standalone preview.

The desktop banner and title use existing app-name bridge calls; there are no
new FFI functions. Android, iOS and Web are excluded from this desktop workflow.
