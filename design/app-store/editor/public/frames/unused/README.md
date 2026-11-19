Apple bezels moved out of `public/frames/` on purpose so the editor uses its built-in
frames (`/mockup.png` for iPhone, `IPad` in device-frames.tsx). The bezels' screen
cutouts (iPhone 1320x2717 = 0.486, iPad 2064x2752 = 0.750) do not match the native
captures (iPhone 1178x2556 = 0.461, iPad 1640x2360 = 0.695), so they would letterbox.
Move a file back to `public/frames/` to use it again.
