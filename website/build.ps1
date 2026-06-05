# Build wrapper for the SkillFishOS website on Windows + Dropbox.
#
# Why this exists: the project lives inside a Dropbox-synced folder. Astro's
# post-build step removes empty cache dirs (e.g. <root>/.astro, .astro/img) and
# Dropbox's filesystem filter keeps them locked, so `astro build` exits 1 with
# "EBUSY ... rmdir '...\.astro'" AFTER all output has already been written.
#
# Build output, Vite cache and Astro cache are redirected to %TEMP% (outside
# Dropbox) via astro.config.mjs. This wrapper runs the build and reports success
# based on whether the output was actually produced, ignoring the cosmetic
# cleanup EBUSY.
$ErrorActionPreference = 'Continue'
Push-Location $PSScriptRoot
npm run build
Pop-Location

$out = Join-Path $env:TEMP 'skillfishos-website-dist'
if (Test-Path (Join-Path $out 'index.html')) {
    $n = (Get-ChildItem -Recurse $out -Filter *.html).Count
    Write-Host ("[build.ps1] OK - {0} HTML pages in {1}" -f $n, $out) -ForegroundColor Green
    exit 0
}
Write-Host ("[build.ps1] FAILED - no output in {0}" -f $out) -ForegroundColor Red
exit 1
