# gh-amp-package-pusher
Create Push Packages for Amp Contesting/rewards/email to Github Package repo. Custom made for AMP Suite

Note: this is only useful for the publishing the amp suite.  If you came across this for some reason then i recommend to not use it.

Thanks

## Usage

```yml
- name: AMP Suite Package Publisher
uses: TDASinternal/gh-amp-package-pusher@vX.X.X
if: ${{ matrix.BUILD_PROJECT.PACKAGES != null }}
id: package-pusher
with:
    RV_MAJOR                : ${{ steps.version.outputs.RV_MAJOR }}
    RV_MINOR                : ${{ steps.version.outputs.RV_MINOR }}
    RV_PATCH                : ${{ steps.version.outputs.RV_PATCH }}
    PACKAGES                : ${{ toJSON(matrix.BUILD_PROJECT.PACKAGES) }}
    PACKAGE_DIR             : ${{ github.workspace }}\_work\build\Deploy
    BUILD_NUMBER            : ${{ env.BUILD_NUMBER }}
    RELEASE_NOTES_FILE_PATH : ${{ github.workspace }}\RELEASE_NOTES.md
    NUGET_PACKAGE_URI       : https://nuget.pkg.github.com/TDASInternal/index.json
    NUGET_PACKAGE_USERNAME  : TDASinternal


```
