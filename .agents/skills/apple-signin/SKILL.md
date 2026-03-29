---
name: "apple-signin"
description: "Use when implementing Apple Sign-In. Covers entitlement setup, AuthenticationServices framework, SwiftUI SignInWithAppleButton, and credential state checking."
---

# Apple Sign-In

Implement Sign in with Apple using the native AuthenticationServices framework.

## Step 1: Add Entitlement

Via xcodegen MCP:
```
mcp__xcodegen__add_entitlement with:
  key: "com.apple.developer.applesignin"
  value: ["Default"]
```

## Step 2: Add Capability in Developer Portal

1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Certificates, Identifiers & Profiles → Identifiers
3. Select your App ID
4. Enable "Sign In with Apple" capability

## Step 3: SwiftUI Sign-In Button

```swift
import AuthenticationServices

struct SignInView: View {
    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                handleAuthorization(authorization)
            case .failure(let error):
                handleError(error)
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .clipShape(.rect(cornerRadius: AppTheme.Style.cornerRadius))
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func handleAuthorization(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }

        let userID = credential.user
        let identityToken = credential.identityToken
        let email = credential.email           // Only on first sign-in
        let fullName = credential.fullName     // Only on first sign-in

        // Store userID in Keychain for future credential checks
        // Send identityToken to your backend if using server-side auth
    }

    private func handleError(_ error: Error) {
        // Handle ASAuthorizationError
        // .canceled — user dismissed
        // .failed — authorization failed
        // .invalidResponse — invalid response
        // .notHandled — not handled
    }
}
```

## Step 4: Check Credential State on Launch

```swift
func checkAppleSignInCredentialState() async {
    let provider = ASAuthorizationAppleIDProvider()
    do {
        let state = try await provider.credentialState(forUserID: storedUserID)
        switch state {
        case .authorized:
            // User is still signed in
            break
        case .revoked:
            // User revoked — sign out locally
            break
        case .notFound:
            // No credential found — show sign-in
            break
        default:
            break
        }
    } catch {
        // Handle error
    }
}
```

Call this in your app's `.task` or `AppDelegate.didFinishLaunching`.

## Step 5: AuthService Pattern

```swift
import AuthenticationServices

@MainActor @Observable
final class AuthService {
    var isSignedIn = false
    var userID: String?

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        userID = credential.user
        isSignedIn = true
        // Store userID in Keychain
    }

    func checkCredentialState() async {
        guard let userID else { return }
        let provider = ASAuthorizationAppleIDProvider()
        let state = try? await provider.credentialState(forUserID: userID)
        isSignedIn = (state == .authorized)
    }

    func signOut() {
        userID = nil
        isSignedIn = false
        // Remove from Keychain
    }
}
```

## Notes

- Email and full name are only provided on the FIRST sign-in. Store them immediately.
- The `user` identifier is stable across sign-ins. Use it as the primary key.
- For backend auth (Supabase, Firebase, etc.), send the `identityToken` to your server.
- Apple requires the sign-in button to follow their [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple).
