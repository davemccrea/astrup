# HappiHub Roadmap

## Next

- [ ] When in multi mode, it shouldn't be possible to switch leads with the keyboard #bug
- [ ] Fix error: TypeError: this.updateFullscreenStyles is not a function. (In 'this.updateFullscreenStyles(this.isFullscreen)', 'this.updateFullscreenStyles' is undefined) #bug
- [ ] The Display Modes should be called "Single Lead" and "Multi Lead"
- [ ] When in "Multi Lead" mode, the user should be able to change the layout. The current layout, plus a two colum layout. Left column: leads I II III aVR aVL aVF. Right column: V1, V2, V3, V4, V5, V6.
- [ ] Allow users to add and save notes to ECG recordings #feature
- [ ] Prevent play/pause when no ECG is loaded (add tests) #bug
- [ ] Show helpful placeholder when no ECGs are saved #feature
- [ ] Improved loading indicators throughout the application, i.e. spinners
- [ ] Improve error handling throughout the ECG viewer #improvement
- [ ] PDF/PNG export of ECG views #feature
- [ ] Add comprehensive application monitoring and diagnostics #improvement

## Current

- [ ] Check that the tests for the new caliper tool are accurate and comprehensive

## Done

### 2025/07/17

- [x] **Caliper Button State Preservation Fix** - Fixed caliper button state not updating after LiveView display mode changes by adding proper synchronization between server and client state ✅ 2025/07/17
- [x] **Multiple Caliper Bug Fix** - Fixed bug where multiple calipers could be drawn; now only allows one caliper at a time ✅ 2025/07/17
- [x] **Caliper Button State Preservation** - Fixed caliper button state not being preserved when switching between single/multi mode ✅ 2025/07/17

### 2025/07/16

- [x] **Save Button Canvas Fix** - Fixed canvas clearing issue when save button is pressed
- [x] **Fullscreen Mode** - Implemented fullscreen mode for ECG viewer with Tailwind CSS integration
- [x] **Multi-Lead Grid Alignment** - Fixed visual discontinuities in multi-lead view using unified continuous grid approach
- [x] **URL Parameter Loading** - ECG Viewer now loads ECGs from URL params only
- [x] **Missing ECG Message** - Show appropriate message when ECG not found or no params provided
- [x] **Project Documentation** - Added CLAUDE.md with project overview and development methodology
