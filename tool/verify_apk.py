"""Verify the packaged manifest and OTA channels inside the GitHub APK, without installing it.

Android SDK apkanalyzer must be available.
Only the exact artifact passed to this command is inspected.
"""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile

ANDROID = "{http://schemas.android.com/apk/res/android}"
INSTALL = "android.permission.REQUEST_INSTALL_PACKAGES"
FORBIDDEN = {"android.permission.INSTALL_PACKAGES",
             "android.permission.WRITE_EXTERNAL_STORAGE",
             "android.permission.READ_EXTERNAL_STORAGE"}
PROVIDER = "sk.fourq.otaupdate.OtaUpdateFileProvider"


def verify_manifest(xml):
    root = ET.fromstring(xml)
    permissions = {e.get(ANDROID + "name") for e in root if e.tag.startswith("uses-permission")}
    components = [e for e in root.findall("application/*")
                  if e.tag in {"activity", "activity-alias", "provider", "receiver", "service"}]
    ota = [e for e in components if "sk.fourq.otaupdate" in e.get(ANDROID + "name", "")
           or ".ota_update_provider" in e.get(ANDROID + "authorities", "")]
    if root.get("package") != "com.example.showtracker":
        raise ValueError("Unexpected applicationId")
    if permissions & FORBIDDEN:
        raise ValueError("Unnecessary system installer/external storage permission")
    providers = [e for e in ota if e.get(ANDROID + "name") == PROVIDER]
    if INSTALL not in permissions or len(providers) != 1:
        raise ValueError("Missing OTA permission/provider")
    provider = providers[0]
    if (provider.get(ANDROID + "exported") != "false"
            or provider.get(ANDROID + "grantUriPermissions") != "true"
            or provider.get(ANDROID + "authorities") != "com.example.showtracker.ota_update_provider"):
        raise ValueError("Unsafe or changed OTA provider identity")
    # Stable identity and security must survive the plugin manifest merge.
    names = {e.get(ANDROID + "name", "") for e in components}
    background = next((e for e in components if e.get(ANDROID + "name") ==
                       "es.antonborri.home_widget.HomeWidgetBackgroundReceiver"), None)
    if background is None or background.get(ANDROID + "exported") != "false":
        raise ValueError("HomeWidget background receiver must be private")
    public = {"com.example.showtracker.MainActivity",
              "com.example.showtracker.MaratonaWidgetProvider",
              "com.example.showtracker.ProssimamenteWidgetProvider"}
    system_permissions = {"android.permission.BIND_JOB_SERVICE",
                          "android.permission.BIND_REMOTEVIEWS", "android.permission.DUMP"}
    for component in components:
        if (component.get(ANDROID + "exported") == "true"
                and component.get(ANDROID + "name") not in public
                and component.get(ANDROID + "permission") not in system_permissions):
            raise ValueError("Unexpected unprotected exported component")
    for widget in ("MaratonaWidgetProvider", "ProssimamenteWidgetProvider"):
        if not any(name.endswith("." + widget) for name in names):
            raise ValueError("Missing stable widget component: " + widget)
    if "android.permission.INTERNET" not in permissions:
        raise ValueError("Missing shared network permission")
    return sorted(permissions)


def find_apkanalyzer():
    executable = shutil.which("apkanalyzer") or shutil.which("apkanalyzer.bat")
    if executable:
        return executable
    sdk = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if not sdk:
        properties = Path(__file__).resolve().parents[1] / "android/local.properties"
        if properties.exists():
            for line in properties.read_text().splitlines():
                if line.startswith("sdk.dir="):
                    sdk = line.split("=", 1)[1].replace("\\\\", "\\").replace("\\:", ":")
    if sdk:
        suffix = ".bat" if os.name == "nt" else ""
        candidate = Path(sdk) / "cmdline-tools/latest/bin" / ("apkanalyzer" + suffix)
        if candidate.is_file():
            return str(candidate)
    raise ValueError("Provide --apkanalyzer or install Android SDK command-line tools")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--apkanalyzer")
    args = parser.parse_args()
    artifact = args.artifact.resolve(strict=True)
    if artifact.suffix != ".apk":
        raise ValueError("Expected .apk")
    command = [args.apkanalyzer or find_apkanalyzer(), "manifest", "print", str(artifact)]
    result = subprocess.run(command, check=True, capture_output=True, text=True, encoding="utf-8")
    permissions = verify_manifest(result.stdout)
    with zipfile.ZipFile(artifact) as archive:
        dex = b"".join(archive.read(n) for n in archive.namelist() if n.endswith(".dex"))
        for marker in (b"showtracker/install_permission", b"sk.fourq.ota_update/stream"):
            if marker not in dex:
                raise ValueError("Missing OTA native channel: " + marker.decode())
    print("OK:", artifact)
    print("Manifest permissions:", ", ".join(permissions))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError, ET.ParseError) as error:
        print("FAILED:", error, file=sys.stderr)
        sys.exit(1)
