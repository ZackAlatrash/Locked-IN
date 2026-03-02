# Fix: Large Nav Title Color Caching on Theme Switch

## Steps

- [x] 1. Create `LockedIn/CoreUI/Components/NavigationBarTitleColorFix.swift` — UIViewControllerRepresentable that explicitly sets large-title text attributes on the parent UINavigationBar
- [x] 2. Edit `LockedIn/Features/Cockpit/Views/CockpitView.swift` — Apply the fix as a background view inside the NavigationStack, driven by `usesModernLightMode`
- [ ] 3. Verify no build errors
