import os, urllib.request, subprocess

def create_icns(png_url, output_icns):
    tmp_png = "/tmp/app_icon.png"
    iconset = "/tmp/app.iconset"
    try:
        req = urllib.request.Request(png_url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as resp, open(tmp_png, 'wb') as f:
            f.write(resp.read())
        
        os.makedirs(iconset, exist_ok=True)
        # Generate icon sizes
        sizes = [16, 32, 64, 128, 256, 512]
        for s in sizes:
            subprocess.run(["sips", "-z", str(s), str(s), tmp_png, "--out", f"{iconset}/icon_{s}x{s}.png"], check=True, stdout=subprocess.DEVNULL)
            subprocess.run(["sips", "-z", str(s*2), str(s*2), tmp_png, "--out", f"{iconset}/icon_{s}x{s}@2x.png"], check=True, stdout=subprocess.DEVNULL)
        
        subprocess.run(["iconutil", "-c", "icns", iconset, "-o", output_icns], check=True, stdout=subprocess.DEVNULL)
        print(f"Generated {output_icns}")
    except Exception as e:
        print(f"Failed to generate {output_icns}: {e}")

apps_dir = os.path.expanduser("~/Applications")

# Official High-Res Icons
icons = {
    "YouTube": "https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/YouTube_full-color_icon_%282017%29.svg/512px-YouTube_full-color_icon_%282017%29.svg.png",
    "Google Play Store": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Google_Play_2022_logo.svg/512px-Google_Play_2022_logo.svg.png",
    "Parametres Android": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Android_Settings_Icon.png/512px-Android_Settings_Icon.png"
}

for name, url in icons.items():
    res_dir = os.path.join(apps_dir, f"{name}.app", "Contents", "Resources")
    os.makedirs(res_dir, exist_ok=True)
    icns_path = os.path.join(res_dir, "AppIcon.icns")
    create_icns(url, icns_path)
    
    # Update Info.plist to register AppIcon
    plist_path = os.path.join(apps_dir, f"{name}.app", "Contents", "Info.plist")
    if os.path.exists(plist_path):
        with open(plist_path, "r") as f:
            content = f.read()
        if "CFBundleIconFile" not in content:
            content = content.replace("</dict>", "    <key>CFBundleIconFile</key><string>AppIcon</string>\n</dict>")
            with open(plist_path, "w") as f:
                f.write(content)
        subprocess.run(["touch", os.path.join(apps_dir, f"{name}.app")])

print("Icons updated successfully!")
