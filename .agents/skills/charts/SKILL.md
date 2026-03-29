---
name: "charts"
description: "Use when implementing data visualizations. Covers Swift Charts: BarMark, LineMark, AreaMark, axis customization, scrollable charts."
---

# Swift Charts

Use this guide when implementing or modifying chart/data visualization features.

## Framework
`import Charts`

## Basic Chart Container
```swift
Chart {
    ForEach(data) { item in
        BarMark(
            x: .value("Category", item.category),
            y: .value("Value", item.value)
        )
    }
}
```

## Mark Types
| Mark | Use Case |
|------|----------|
| `BarMark` | Comparisons, distributions, categories |
| `LineMark` | Trends over time |
| `AreaMark` | Cumulative values, ranges |
| `PointMark` | Scatter plots, data points |
| `RuleMark` | Reference lines, thresholds |

## Color Coding
```swift
BarMark(x: .value("Day", item.day), y: .value("Count", item.count))
    .foregroundStyle(by: .value("Category", item.category))
```

## Axis Customization
```swift
Chart { ... }
    .chartXAxis {
        AxisMarks(values: .stride(by: .day, count: 4)) { value in
            AxisValueLabel(format: .dateTime.day().month())
        }
    }
    .chartYAxis {
        AxisMarks { value in
            AxisGridLine()
            AxisValueLabel()
        }
    }
```

## Scrollable Charts (large datasets)
```swift
Chart { ... }
    .chartScrollableAxes(.horizontal)
    .chartXVisibleDomain(length: 7)  // Show 7 items at a time
```

## Rules
- Extract `Chart` into a separate computed property — avoid body complexity
- Use `AppTheme.Colors.*` for chart colors, not hardcoded values
- Prefer `BarMark` for discrete categories, `LineMark` for continuous trends
- Add `.chartYScale(domain: 0...10)` when the scale should be fixed
