#!/bin/bash
# Scaffolds a new iOS project from scratch.
# Usage: scaffold-project.sh "AppName" "com.company.appname" [--dir /path/to/output]
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: scaffold-project.sh \"AppName\" \"com.company.appname\" [--dir /path/to/output]" >&2
  exit 1
fi

APP_NAME="$1"
BUNDLE_ID="$2"
shift 2

OUTPUT_DIR="."
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) OUTPUT_DIR="$2"; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

# Check xcodegen
if ! command -v xcodegen &>/dev/null; then
  echo "ERROR: xcodegen is required. Install with: brew install xcodegen" >&2
  exit 1
fi

PROJECT_DIR="$OUTPUT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "Scaffolding $APP_NAME ($BUNDLE_ID)..."

# Create directory structure
mkdir -p "$APP_NAME/App"
mkdir -p "$APP_NAME/Models"
mkdir -p "$APP_NAME/Features/Common"
mkdir -p "$APP_NAME/Theme"
mkdir -p "$APP_NAME/Services"
mkdir -p "$APP_NAME/Shared"
mkdir -p "$APP_NAME/Resources"

# Create Assets.xcassets
mkdir -p "$APP_NAME/Resources/Assets.xcassets/AppIcon.appiconset"
cat > "$APP_NAME/Resources/Assets.xcassets/Contents.json" << 'EOF'
{"info":{"version":1,"author":"xcode"}}
EOF
cat > "$APP_NAME/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json" << 'EOF'
{"images":[{"filename":"AppIcon.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"version":1,"author":"xcode"}}
EOF

# Create project_config.json
cat > "project_config.json" << EOF
{
  "app_name": "$APP_NAME",
  "bundle_id": "$BUNDLE_ID",
  "platform": "ios",
  "deployment_target": "26.0",
  "swift_version": "6",
  "xcode_version": "16.3"
}
EOF

# Create project.yml for xcodegen
cat > "project.yml" << EOF
name: $APP_NAME
options:
  bundleIdPrefix: $(echo "$BUNDLE_ID" | sed "s/\.[^.]*$//")
  deploymentTarget:
    iOS: "26.0"
  xcodeVersion: "16.3"
  defaultActorIsolation: MainActor
settings:
  base:
    SWIFT_VERSION: "6"
    PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID
    INFOPLIST_FILE: $APP_NAME/Resources/Info.plist
    ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
    SWIFT_STRICT_CONCURRENCY: complete
    SWIFT_APPROACHABLE_CONCURRENCY: YES
    CODE_SIGNING_ALLOWED: "NO"
targets:
  $APP_NAME:
    type: application
    platform: iOS
    sources:
      - path: $APP_NAME
    resources:
      - path: $APP_NAME/Resources
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID
EOF

# Create Info.plist
cat > "$APP_NAME/Resources/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>UILaunchScreen</key>
	<dict/>
</dict>
</plist>
EOF

# Create starter Swift files
cat > "$APP_NAME/App/${APP_NAME}App.swift" << EOF
import SwiftUI

@main
struct ${APP_NAME}App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
EOF

cat > "$APP_NAME/App/ContentView.swift" << EOF
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            Text("Welcome to $APP_NAME")
                .font(AppTheme.Fonts.title)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
    }
}

#Preview {
    ContentView()
}
EOF

cat > "$APP_NAME/Theme/AppTheme.swift" << 'EOF'
import SwiftUI

enum AppTheme {
    enum Colors {
        static let primary = Color(hex: "6366F1")
        static let secondary = Color(hex: "8B5CF6")
        static let accent = Color(hex: "EC4899")
        static let background = Color(hex: "FFFFFF")
        static let surface = Color(hex: "F9FAFB")
        static let textPrimary = Color(hex: "111827")
        static let textSecondary = Color(hex: "6B7280")
        static let textTertiary = Color(hex: "9CA3AF")
        static let error = Color(hex: "EF4444")
        static let success = Color(hex: "22C55E")
        static let warning = Color(hex: "F59E0B")
    }

    enum Fonts {
        static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let title = Font.system(.title, design: .rounded, weight: .bold)
        static let title2 = Font.system(.title2, design: .rounded, weight: .semibold)
        static let title3 = Font.system(.title3, design: .rounded, weight: .semibold)
        static let headline = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .rounded)
        static let callout = Font.system(.callout, design: .rounded)
        static let subheadline = Font.system(.subheadline, design: .rounded)
        static let footnote = Font.system(.footnote, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
        static let caption2 = Font.system(.caption2, design: .rounded)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 40
    }

    enum Style {
        static let cornerRadius: CGFloat = 12
        static let cardCornerRadius: CGFloat = 16
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        self.init(
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgbValue & 0x0000FF) / 255.0
        )
    }
}
EOF

cat > "$APP_NAME/Shared/Loadable.swift" << 'EOF'
import Foundation

enum Loadable<T> {
    case notInitiated
    case loading
    case success(T)
    case failure(Error)

    var value: T? {
        if case .success(let v) = self { return v }
        return nil
    }

    var error: Error? {
        if case .failure(let e) = self { return e }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
EOF

# Create .gitignore
cat > ".gitignore" << 'EOF'
# Xcode
*.xcodeproj/project.xcworkspace/
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/
DerivedData/
build/
*.ipa
*.dSYM.zip
*.dSYM

# Swift Package Manager
.build/
Packages/
Package.pins
Package.resolved

# Claude Code
.claude/settings.local.json
screenshots/

# Misc
.DS_Store
*.swp
*.orig
EOF

# Generate Xcode project
echo "Running xcodegen..."
xcodegen generate 2>&1

# Git init
git init
git add -A
git commit -m "Initial scaffold: $APP_NAME"

echo ""
echo "Project scaffolded successfully!"
echo "  Directory: $PROJECT_DIR"
echo "  App: $APP_NAME"
echo "  Bundle ID: $BUNDLE_ID"
echo "  Xcode project: ${APP_NAME}.xcodeproj"
echo ""
echo "Next steps:"
echo "  1. Open ${APP_NAME}.xcodeproj in Xcode"
echo "  2. Or run: bash .claude/scripts/xcode-build.sh"
