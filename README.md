# TeleBank UI - Codespaces Notes

## Push to GitHub
1. Create a new GitHub repo (empty).
2. Upload the project files to the repo and commit.
3. Open the repo and create a Codespace.

## Codespaces setup
Run these from the Codespaces terminal:
```bash
flutter doctor
flutter pub get
```

If `flutter` is not found, install Flutter in the Codespace and re-run the commands above.

## Run
```bash
flutter run
```

## App icon
1. Put your PNG icon at `assets/icon.png` (1024x1024 recommended).
2. Generate platform icons:
```bash
flutter pub run flutter_launcher_icons
```
