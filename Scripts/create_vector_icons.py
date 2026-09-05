import os, subprocess

apps_dir = os.path.expanduser("~/Applications")

def create_badge(name, color_hex, text, symbol_type):
    res_dir = os.path.join(apps_dir, f"{name}.app", "Contents", "Resources")
    os.makedirs(res_dir, exist_ok=True)
    iconset = f"/tmp/{name}.iconset"
    os.makedirs(iconset, exist_ok=True)
    
    # Generate an SVG
    svg_path = f"/tmp/{name}.svg"
    base_png = f"/tmp/{name}_1024.png"
    
    if symbol_type == "play":
        # YouTube play icon
        inner = '<path d="M 360 280 L 700 512 L 360 744 Z" fill="white"/>'
    elif symbol_type == "bag":
        # Play store shopping bag / triangle
        inner = '<path d="M 280 200 L 760 512 L 280 824 Z" fill="white"/>'
    else:
        # Gear / Android
        inner = '<circle cx="512" cy="512" r="220" fill="white"/>'
        
    svg_data = f"""<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:{color_hex};stop-opacity:1" />
          <stop offset="100%" style="stop-color:#111111;stop-opacity:0.8" />
        </linearGradient>
      </defs>
      <rect width="900" height="900" x="62" y="62" rx="200" ry="200" fill="url(#grad)" />
      {inner}
    </svg>"""
    
    with open(svg_path, "w") as f:
        f.write(svg_data)
        
    # Convert svg to png via sips or quicklook / python
    subprocess.run(["qlmanage", "-t", "-s", "1024", "-o", "/tmp", svg_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    rendered = f"/tmp/{os.path.basename(svg_path)}.png"
    if not os.path.exists(rendered):
        # Fallback sips
        rendered = base_png
        subprocess.run(["sips", "-s", "format", "png", svg_path, "--out", rendered], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
    if os.path.exists(rendered):
        sizes = [16, 32, 64, 128, 256, 512]
        for s in sizes:
            subprocess.run(["sips", "-z", str(s), str(s), rendered, "--out", f"{iconset}/icon_{s}x${s}.png"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["sips", "-z", str(s*2), str(s*2), rendered, "--out", f"{iconset}/icon_{s}x${s}@2x.png"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            
        subprocess.run(["iconutil", "-c", "icns", iconset, "-o", f"{res_dir}/AppIcon.icns"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        # Plist CFBundleIconFile
        plist = os.path.join(apps_dir, f"{name}.app", "Contents", "Info.plist")
        if os.path.exists(plist):
            with open(plist, "r") as pf:
                pcontent = pf.read()
            if "CFBundleIconFile" not in pcontent:
                pcontent = pcontent.replace("</dict>", "    <key>CFBundleIconFile</key><string>AppIcon</string>\n</dict>")
                with open(plist, "w") as pf:
                    pf.write(pcontent)
        print(f"Generated AppIcon.icns for {name}")

create_badge("YouTube", "#FF0000", "YT", "play")
create_badge("Google Play Store", "#0086F8", "PLAY", "bag")
create_badge("Parametres Android", "#4CAF50", "SET", "gear")

subprocess.run(["touch", f"{apps_dir}/YouTube.app"])
subprocess.run(["touch", f"{apps_dir}/Google Play Store.app"])
subprocess.run(["touch", f"{apps_dir}/Parametres Android.app"])
print("All native app icons updated.")
