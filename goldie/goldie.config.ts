import type { GoldieConfig } from "goldie";

const APP_ROOT = "/home/joviallaps/Desktop/Ub-Hub";

const config: GoldieConfig = {
  appRoot: APP_ROOT,

  // Unused on this Linux host (no iOS simulator), but required by the config
  // type. Fill in with a real Release-iphonesimulator .app and bundle id if
  // an "iphone-6.9" device is ever added to `devices` on a Mac.
  appPath: "unused-no-ios-on-this-host",
  bundleId: "com.ebongsume.gostudy",

  // Linux host: only the Android/Play device can run here (no iOS simulator).
  // Requires a booted emulator whose AVD hardware profile is "pixel_10_pro"
  // or "pixel_9_pro" (avdmanager list device). See README for creating one.
  android: {
    appPath: `${APP_ROOT}/build/app/outputs/flutter-apk/app-release.apk`,
    applicationId: "com.ebongsume.gostudy",
  },

  devices: ["pixel-10-pro"],
  locales: ["en-US"],
  appearance: "light",

  // Required by the config schema even for Android-only devices (goldie
  // validates it at load time); android tiles use the bundled Pixel 10 Pro
  // bezel regardless, so this variant only matters if an iOS device is
  // added to `devices` later.
  frame: { variant: "17-pro-silver" },

  theme: {
    // Soft blue-tinted gradient matching the app's Material 3 blue accent
    // (ColorScheme.fromSeed(seedColor: Colors.blue) in lib/theme_provider.dart).
    background: "linear-gradient(160deg, #E8F1FF 0%, #F7FAFF 55%, #FFFFFF 100%)",
    headlineColor: "#0F172A", // matches the app's dark text color
    subheadColor: "#5A6A7D",
    fontFamily: '"DM Sans", system-ui, sans-serif',
    template: "editorial",
  },

  store: {
    name: "GoStudy",
    subtitle: { "en-US": "Your academic companion" },
    developer: "Ebong Sume",
    category: "Education",
    rating: 4.8,
    ratingCount: "New",
    ageRating: "4+",
    price: "Free",
    description: {
      "en-US":
        "GoStudy brings everything a student needs into one app: an AI study " +
        "assistant powered by Gemini, an offline course library, real-time " +
        "student chat, and tools to track exams, tasks, and focus time.",
    },
  },

  // TODO(Step 2/3 of the goldie skill): explore the app on a booted
  // pixel-10-pro emulator with argent MCP tools, then replace this with
  // 4-5 screenshot scenes plus one preview scene. Candidate screens based on
  // README.md / FLYER_PITCH.md (verify against the real running app before
  // writing flows):
  //   1. Home/dashboard        - overview of courses, tasks, exams
  //   2. AI study assistant    - Gemini-powered Q&A
  //   3. Offline library       - course materials/PDFs available offline
  //   4. Global chat           - real-time student chat
  //   5. Exam/task scheduler   - focus timer + deadlines
  // Flows go in .argent/flows/store-01-<scene>.yaml etc.
  scenes: [],
};

export default config;
