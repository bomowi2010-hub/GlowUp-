# Glow Up: backend and APK build brief

## Stack
Supabase (auth, Postgres, storage) + this web app wrapped with Capacitor. RevenueCat for Google Play subscriptions.

## Steps
1. Create a Supabase project. Run `schema.sql`. Create a private storage bucket `progress-photos`.
2. Replace localStorage in `glowup.html` with Supabase calls: sign up and log in (email or Google), profile, logs, checks, photos (upload to the private bucket), posts, comments, DMs (realtime subscription).
3. Community safety: report and block buttons, an admin table view to hide posts, a profanity filter, rate limits. No public photo sharing.
4. Premium: RevenueCat webhook sets `profiles.premium`. The app must never write it.
5. APK: `npm i @capacitor/core @capacitor/cli @capacitor/android`, `npx cap init GlowUp com.yourname.glowup`, put the built page in `www/`, `npx cap add android`, `npx cap sync`, open in Android Studio and choose Build, Generate Signed Bundle/APK. Use `logo.svg` for the icon.
6. Before Play Store: privacy policy, delete-account button (already in the app, wire it to the server), age gate, data-safety form. If you launch in South Africa, POPIA applies, and the safest choice is to make accounts 18+.

## Prompt for Claude Code
"Read glowup.html, schema.sql and this file. Implement steps 2 to 5, keep the visual design unchanged, and list every place you changed behaviour."
