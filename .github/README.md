# Continuous integration

[The Lazarus / FPC workflow](workflows/main.yml) runs on pushes, pull requests and
manual dispatch. It uses Windows Server 2025 and the official, pinned Lazarus 4.8
distribution with Free Pascal 3.2.2. The installer checksum is checked before it
runs on the disposable GitHub-hosted runner. Version and checksum updates belong
together; obtain both from the [official release](https://sourceforge.net/projects/lazarus/files/Lazarus%20Windows%2064%20bits/Lazarus%204.8/)
and [published checksums](https://www.lazarus-ide.org/index.php?page=checksums).

Downloads start with the [publisher's mirror](https://download.lazarus-ide.org/)
and have bounded SourceForge fallbacks because a mirror can return an HTML
download page with HTTP 200. Every attempt logs its size, content type and
SHA256; only the pinned checksum permits installation. A failed download never
weakens verification or runs the returned page.

Checkout and artifact upload use the official [checkout v7.0.1](https://github.com/actions/checkout/releases/tag/v7.0.1)
and [upload-artifact v7.0.2](https://github.com/actions/upload-artifact/releases/tag/v7.0.2)
commits, pinned by SHA. The checkout step does not retain Git credentials.

The job builds the root Lazarus package and the unified grid/wizard/cache demo,
then runs the existing Windows [FPCUnit suite](../tests/README.md). Its Lazarus
configuration is isolated, and installation selects no desktop icons or file
associations. Build and installer logs are retained for 14 days. Native private
desktop probes remain separate commands in the test guide.

The [Actions page](https://github.com/HermanSchoenfeld/PascalFramework/actions/workflows/main.yml)
and README status badge show the hosted result for the published revision.
Running the same commands locally verifies source/build/test behavior; it does
not verify the hosted Windows Server installation step. Installer execution is
restricted to disposable GitHub-hosted runners. Local compiler/native checks and
their scope are documented in the [test guide](../tests/README.md).

Delphi is verified through the actual Delphi 13 IDE and native VCL probes.
Community Edition's command-line restriction means this workflow does not run
`dcc32`, `dcc64` or a Delphi MSBuild job. An automated Delphi job would require a
separately provisioned, appropriately licensed compiler and runner.
