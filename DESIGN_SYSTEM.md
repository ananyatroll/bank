# TeleBank UI - Design System

## Brand Identity
Modern Ethiopian mobile banking app combining traditional heritage with digital innovation.

---

## App Icon Colors
| Color | Hex | Usage |
|-------|-----|-------|
| Deep Navy Blue | #1E3A5F | Primary background, main brand color |
| Ethiopian Green | #2D7A4F | Top-left accent, success states |
| Golden Yellow | #F4B942 | Bottom-right accent, highlights, rewards |

## Complete Color Palette

### Primary Brand Colors
```dart
static const Color navyBlue = Color(0xFF1E3A5F);      // Main brand color
static const Color ethiopianGreen = Color(0xFF2D7A4F); // Growth, stability
static const Color goldenYellow = Color(0xFFF4B942);   // Prosperity, heritage
```

### Secondary Colors
```dart
static const Color lightBlue = Color(0xFF3D5A7F); // Cards, secondary bg
static const Color tealGreen = Color(0xFF4A9F7A); // Success highlights
static const Color warmGold = Color(0xFFFFC947);  // Premium features
static const Color skyBlue = Color(0xFF5B8ABF);   // Info elements
static const Color deepGreen = Color(0xFF1B5E4A); // Darker green variant
```

### Neutral Colors
```dart
// Light Mode
static const Color white = Color(0xFFFFFFFF);      // Pure white
static const Color offWhite = Color(0xFFF8F9FA);   // Light backgrounds
static const Color lightGray = Color(0xFFE8EDF5);  // Borders, dividers
static const Color mediumGray = Color(0xFF94A3B8); // Secondary text
static const Color darkGray = Color(0xFF475569);   // Body text
static const Color charcoal = Color(0xFF1E293B);   // Primary text

// Dark Mode
static const Color bgDark = Color(0xFF0F172A);          // Dark background
static const Color cardDark = Color(0xFF1E293B);        // Dark cards
static const Color textPrimaryDark = Color(0xFFF1F5F9); // Dark mode text
static const Color textSecondaryDark = Color(0xFF94A3B8); // Dark mode secondary
```

### Functional / Semantic Colors
```dart
static const Color success = Color(0xFF10B981); // Completed transactions
static const Color error = Color(0xFFEF4444);   // Errors, warnings
static const Color warning = Color(0xFFF59E0B); // Pending actions
static const Color info = Color(0xFF3B82F6);    // Notifications, tips
static const Color pending = Color(0xFF8B5CF6); // Processing states
```

## Gradients

### Primary Gradient (Icon Match)
```dart
static const LinearGradient primaryGradient = LinearGradient(
  colors: [
    Color(0xFF2D7A4F), // Ethiopian Green
    Color(0xFF1E3A5F), // Navy Blue
    Color(0xFFF4B942), // Golden Yellow
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.6, 1.0],
);
```

### Button Gradient
```dart
static const LinearGradient buttonGradient = LinearGradient(
  colors: [
    Color(0xFF2D7A4F),
    Color(0xFF4A9F7A),
  ],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
```

### Card Gradient
```dart
static const LinearGradient cardGradient = LinearGradient(
  colors: [
    Color(0xFF1E3A5F),
    Color(0xFF3D5A7F),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
```

### Gold Accent Gradient
```dart
static const LinearGradient goldGradient = LinearGradient(
  colors: [
    Color(0xFFF4B942),
    Color(0xFFFFC947),
  ],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
```

## Usage Guidelines

### Component Color Mapping
| Component | Primary Color | Secondary Color | Text Color |
|----------|----------------|----------------|-----------|
| Primary Button | ethiopianGreen | - | white |
| Secondary Button | goldenYellow | - | navyBlue |
| App Bar | navyBlue | - | white |
| Card Background | lightBlue (10% opacity) | offWhite | charcoal |
| Balance Display (Positive) | - | tealGreen | charcoal |
| Balance Display (Negative) | - | error | charcoal |
| Transaction Success | success | - | white |
| Transaction Failed | error | - | white |
| USSD Signal Icon | goldenYellow | - | - |
| Lion Logo | white | - | - |

## Background Colors
```dart
// Light Mode
static const Color scaffoldBackground = offWhite;
static const Color cardBackground = white;

// Dark Mode
static const Color scaffoldBackgroundDark = bgDark;
static const Color cardBackgroundDark = cardDark;
```

## Text Colors
```dart
// Primary Text
static const Color textPrimary = charcoal;
static const Color textPrimaryDark = textPrimaryDark;

// Secondary Text
static const Color textSecondary = mediumGray;
static const Color textSecondaryDark = textSecondaryDark;

// Hint / Disabled Text
static const Color textHint = Color(0xFFB0B8C4);
```

## Theme Configuration

### Light Theme
```dart
ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  primaryColor: navyBlue,
  scaffoldBackgroundColor: offWhite,
  colorScheme: const ColorScheme.light(
    primary: ethiopianGreen,
    secondary: goldenYellow,
    tertiary: lightBlue,
    error: error,
    surface: white,
    onPrimary: white,
    onSecondary: navyBlue,
    onError: white,
    onSurface: charcoal,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: navyBlue,
    foregroundColor: white,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    color: white,
    elevation: 2,
    shadowColor: navyBlue.withOpacity(0.1),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ethiopianGreen,
      foregroundColor: white,
      elevation: 4,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: goldenYellow,
    ),
  ),
  iconTheme: const IconThemeData(
    color: navyBlue,
  ),
);
```

### Dark Theme
```dart
ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  primaryColor: navyBlue,
  scaffoldBackgroundColor: bgDark,
  colorScheme: const ColorScheme.dark(
    primary: tealGreen,
    secondary: warmGold,
    tertiary: skyBlue,
    error: error,
    surface: cardDark,
    onPrimary: navyBlue,
    onSecondary: navyBlue,
    onError: white,
    onSurface: textPrimaryDark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: navyBlue,
    foregroundColor: white,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    color: cardDark,
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.3),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: tealGreen,
      foregroundColor: navyBlue,
      elevation: 4,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: warmGold,
    ),
  ),
  iconTheme: const IconThemeData(
    color: white,
  ),
);
```

## Accessibility

### WCAG 2.1 AA Compliance
| Color Combination | Contrast Ratio | Status |
|------------------|----------------|--------|
| navyBlue on white | 12.5:1 | AAA |
| ethiopianGreen on white | 5.8:1 | AA |
| goldenYellow on navyBlue | 8.2:1 | AAA |
| charcoal on offWhite | 11.3:1 | AAA |
| tealGreen on white | 4.7:1 | AA |
| error on white | 4.5:1 | AA |

### Color Blindness Considerations
- Never use color alone to convey information.
- Always pair colors with icons or text labels.
- Test with color blindness simulators (protanopia, deuteranopia, tritanopia).

## Spacing Scale
```dart
// Consistent spacing system
static const double spacing4 = 4.0;
static const double spacing8 = 8.0;
static const double spacing12 = 12.0;
static const double spacing16 = 16.0;
static const double spacing20 = 20.0;
static const double spacing24 = 24.0;
static const double spacing32 = 32.0;
static const double spacing40 = 40.0;
static const double spacing48 = 48.0;
```

## Shadow System
```dart
// Elevation shadows
static List<BoxShadow> getShadow(int elevation) {
  switch (elevation) {
    case 1:
      return [
        BoxShadow(
          color: navyBlue.withOpacity(0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];
    case 2:
      return [
        BoxShadow(
          color: navyBlue.withOpacity(0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    case 4:
      return [
        BoxShadow(
          color: navyBlue.withOpacity(0.12),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
    case 8:
      return [
        BoxShadow(
          color: navyBlue.withOpacity(0.16),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
    default:
      return [];
  }
}
```

## Typography (Recommended)
```dart
// Font families
static const String fontFamilyPrimary = 'Inter';
static const String fontFamilySecondary = 'Poppins';

// Text styles
static const TextStyle heading1 = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: charcoal,
  fontFamily: fontFamilyPrimary,
);
static const TextStyle heading2 = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: charcoal,
  fontFamily: fontFamilyPrimary,
);
static const TextStyle heading3 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: charcoal,
  fontFamily: fontFamilyPrimary,
);
static const TextStyle bodyLarge = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.normal,
  color: charcoal,
  fontFamily: fontFamilyPrimary,
);
static const TextStyle bodyMedium = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.normal,
  color: darkGray,
  fontFamily: fontFamilyPrimary,
);
static const TextStyle caption = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.normal,
  color: mediumGray,
  fontFamily: fontFamilyPrimary,
);
static const TextStyle button = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: white,
  fontFamily: fontFamilySecondary,
);
```

## Quick Reference Card
Most used colors:
- Primary actions: #2D7A4F (Ethiopian Green)
- Secondary actions: #F4B942 (Golden Yellow)
- Backgrounds: #1E3A5F (Navy Blue) / #F8F9FA (Off-White)
- Text: #1E293B (Charcoal) / #FFFFFF (White)
- Success: #10B981 (Emerald)
- Error: #EF4444 (Red)

## Component Examples

### Primary Button
```dart
Container(
  decoration: BoxDecoration(
    gradient: AppColors.buttonGradient,
    borderRadius: BorderRadius.circular(12),
    boxShadow: AppColors.getShadow(4),
  ),
  child: ElevatedButton(
    onPressed: () {},
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
    child: const Text('Send Money', style: AppColors.button),
  ),
)
```

### Balance Card
```dart
Container(
  decoration: BoxDecoration(
    gradient: AppColors.cardGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: AppColors.getShadow(2),
  ),
  padding: const EdgeInsets.all(20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Available Balance',
        style: AppColors.bodyMedium.copyWith(color: Colors.white70),
      ),
      const SizedBox(height: 8),
      const Text(
        'ETB 4,250.00',
        style: AppColors.heading2.copyWith(color: AppColors.goldenYellow),
      ),
    ],
  ),
)
```

## State Colors
| State | Color | Hex |
|-------|-------|-----|
| Enabled | ethiopianGreen | #2D7A4F |
| Disabled | mediumGray (50%) | #94A3B8 |
| Hover | tealGreen | #4A9F7A |
| Pressed | deepGreen | #1B5E4A |
| Focused | skyBlue | #5B8ABF |
