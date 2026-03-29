---
name: "forms"
description: "Use when implementing form-based UI. Covers TextField, validation, pickers, stepper, slider, form submission flows."
---

# Forms & Input

Use this guide when implementing or modifying form-based UI.

## Form Basics
```swift
Form {
    Section("Profile") {
        TextField("Username", text: $username)
        ColorPicker("Accent Color", selection: $selectedColor)
    }
    Section("Preferences") {
        Toggle("Notifications", isOn: $notificationsEnabled)
    }
}
```

## TextField Patterns
```swift
TextField("Email", text: $email)
    .textContentType(.emailAddress)
    .keyboardType(.emailAddress)
    .autocorrectionDisabled()
    .textInputAutocapitalization(.never)

SecureField("Password", text: $password)
    .textContentType(.password)
```

## Validation
```swift
TextField("Email", text: $email)
    .onChange(of: email) { _, newValue in
        isEmailValid = newValue.contains("@")
    }
    .overlay(alignment: .trailing) {
        if !email.isEmpty {
            Image(systemName: isEmailValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isEmailValid ? AppTheme.Colors.success : AppTheme.Colors.error)
        }
    }
```

## Picker Patterns
- **2-4 options**: `.pickerStyle(.segmented)`
- **5+ options**: Default menu style or NavigationLink to selection list
- **Dates**: `DatePicker` with appropriate `displayedComponents`

```swift
Picker("View", selection: $selectedTab) {
    Text("List").tag(0)
    Text("Grid").tag(1)
}
.pickerStyle(.segmented)
```

## Stepper and Slider
```swift
Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)

Slider(value: $volume, in: 0...100) {
    Text("Volume")
} minimumValueLabel: {
    Image(systemName: "speaker")
} maximumValueLabel: {
    Image(systemName: "speaker.wave.3")
}
```

## Form Submission Pattern
```swift
NavigationStack {
    Form {
        TextField("Name", text: $name)
    }
    .navigationTitle("New Item")
    .toolbar {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { Task { await submit() } }
            .disabled(name.isEmpty || isSubmitting)
        }
    }
}
```
