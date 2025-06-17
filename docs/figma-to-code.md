# The Complete Guide to Figma-to-Code Conversion

A systematic approach to accurately converting Figma designs into
production-ready code using the Figma MCP (Model Context Protocol).

## The Golden Rule

**"Export images first, analyze structure second, extract details third."**

This prevents missing visual elements that are obvious in images but easy to
overlook in JSON data.

## Phase 1: Visual Export & Analysis

### Step 1.1: Export the Full Screen/Component as an Image

This is the **most critical step** that prevents missing UI elements.

```typescript
mcp__figmastrand__figma_get_images({
  fileKey: "YOUR_FILE_KEY",
  ids: "SCREEN_NODE_ID",
  format: "png",
  scale: 2,
  use_absolute_bounds: true, // Includes shadows and effects
});
```

### Step 1.2: Create a Visual Inventory

Open the exported image and document **every visual element** from left to
right, top to bottom:

```markdown
## Visual Inventory for [Screen Name]

### Navigation Bar

- [ ] Title text ("People")
- [ ] Dropdown arrow icon
- [ ] User avatar (circular, initials "ML")
- [ ] Background blur effect

### Content Area

- [ ] Gray background container with rounded corners
- [ ] Person Row 1:
  - [ ] Avatar circle (pink, "JD")
  - [ ] Name text ("Joel Drotleff")
  - [ ] Chevron icon (right side)
- [ ] Separator line
- [ ] Person Row 2:
  - [ ] Avatar circle (orange, "MB")
  - [ ] Name text ("Michał Bortnik")
  - [ ] Chevron icon (right side) [...continue for all elements]

### Tab Bar

- [ ] Inbox icon (inactive state)
- [ ] People icon (active state with background)
- [ ] Border at top

### System Elements

- [ ] Home indicator (black pill at bottom)
```

## Phase 2: Structure Discovery

### Step 2.1: Get File Overview

Start with minimal depth to understand the file structure:

```typescript
const fileOverview = await mcp__figmastrand__figma_get_file({
  fileKey: "YOUR_FILE_KEY",
  depth: 1, // Just top-level pages
});

// Identify the screens/frames you need from the overview
```

### Step 2.2: Map the Node Hierarchy

Create a node map before diving into details:

```
Page 1
└── People screen (1:950)
    ├── Header (1:951)
    ├── People List Container (1:963)
    │   ├── Person Row (1:964)
    │   ├── Separator (1:969)
    │   └── ...
    └── Tab Bar (1:955)
```

## Phase 3: Detailed Data Extraction

### Step 3.1: Get Screen-Level Details

Now get the specific screen with limited depth to avoid token limits:

```typescript
const screenDetails = await mcp__figmastrand__figma_get_file_nodes({
  fileKey: "YOUR_FILE_KEY",
  ids: "SCREEN_NODE_ID",
  depth: 2, // Usually sufficient
  geometry: "paths", // Include vector data for shapes
});
```

### Step 3.2: Extract Design Tokens

#### Get All Text Styles

```typescript
const textStyles = await mcp__figmastrand__figma_get_file_styles({
  fileKey: "YOUR_FILE_KEY",
});
```

#### Get Reusable Components

```typescript
const components = await mcp__figmastrand__figma_get_file_components({
  fileKey: "YOUR_FILE_KEY",
});
```

### Step 3.3: Document Key Measurements

From the node data, extract:

```javascript
// Typography
const typography = {
  title: {
    fontFamily: "Nunito Sans",
    fontWeight: 900, // Black
    fontSize: 28,
    lineHeight: 32,
    color: "#0C0F1A",
  },
  bodyText: {
    fontFamily: "Nunito Sans",
    fontWeight: 700, // Bold
    fontSize: 15,
    lineHeight: 20,
    color: "#0C0F1A",
  },
};

// Spacing
const spacing = {
  screenPadding: 15,
  rowHeight: 30,
  separatorMargin: 15,
  avatarSize: 30,
  // ... etc
};

// Colors - Note opacity handling
const colors = {
  avatarPink: "rgba(240, 81, 109, 0.65)", // #F0516D at 65%
  avatarOrange: "rgba(254, 169, 79, 0.65)", // #FEA94F at 65%
  separatorGray: "rgba(119, 130, 152, 0.05)", // #778298 at 5%
};
```

## Phase 4: Asset Export

### Step 4.1: Batch Export Icons

Export all icons in one call for efficiency:

```typescript
const iconIds = ["icon1_id", "icon2_id", "icon3_id"];

const icons = await mcp__figmastrand__figma_get_images({
  fileKey: "YOUR_FILE_KEY",
  ids: iconIds.join(","),
  format: "svg",
  svg_include_id: false, // Cleaner output
  svg_simplify_stroke: true, // Optimized paths
  svg_outline_text: true, // Convert text to paths
});
```

#### SVG Optimization for macOS Quick Look

When exporting SVGs from Figma, they often have fixed pixel dimensions that
appear tiny in macOS Quick Look preview. Always optimize SVGs for better
viewing:

```svg
<!-- ❌ Figma exports with fixed dimensions (appears tiny in Quick Look) -->
<svg width="24" height="20" viewBox="0 0 24 20" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- SVG content -->
</svg>

<!-- ✅ Optimized for Quick Look (scales properly) -->
<svg width="100%" height="100%" viewBox="0 0 24 20" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- SVG content -->
</svg>
```

**Key points:**

- Change `width` and `height` from fixed pixels to `100%`
- Keep the `viewBox` unchanged to preserve aspect ratio
- This has no effect on web rendering (viewBox maintains dimensions)
- Makes SVGs properly scale in Quick Look and other preview tools

### Step 4.2: Export Other Assets

For images, backgrounds, or special graphics:

```typescript
const assets = await mcp__figmastrand__figma_get_images({
  fileKey: "YOUR_FILE_KEY",
  ids: "asset_ids",
  format: "png",
  scale: 2, // For retina displays
});
```

## Phase 5: Code Implementation

### Step 5.1: Plan Navigation Structure

For multi-screen apps, establish navigation patterns early:

```tsx
// Tab bar navigation example
<div class="fixed bottom-0 left-0 right-0 h-[85px] bg-white border-t">
  <div class="flex h-full items-center justify-around px-[30px]">
    {/* Inbox Tab */}
    <a href="/inbox" class="relative flex items-center justify-center">
      <img src="/assets/icons/inbox-icon.svg" alt="Inbox" class="w-[24px] h-[24px]" />
      {/* Notification badge */}
      <div class="absolute -top-[6px] -right-[6px] w-[18px] h-[18px] bg-[#F0516D] rounded-full">
        <span class="text-white text-[11px] font-extrabold">2</span>
      </div>
    </a>
    
    {/* People Tab (Active) */}
    <a href="/people" class="relative flex items-center justify-center">
      <div class="absolute w-[64px] h-[33px] rounded-[16.5px] bg-gray-100" />
      <img src="/assets/icons/people-icon.svg" alt="People" class="w-[24px] h-[24px] relative z-10" />
    </a>
  </div>
</div>
```

### Step 5.2: Build Structure First

Start with the container and major sections:

```html
<!-- Container matching Figma dimensions -->
<div class="w-[393px] h-[852px] bg-white rounded-[20px] relative overflow-hidden">
  <!-- Navigation Bar -->
  <div class="absolute top-0 left-0 right-0 h-[59px] backdrop-blur-[80px] bg-white/80 z-50">
    <!-- Nav content -->
  </div>

  <!-- Main Content -->
  <div class="pt-[107px] pb-[119px] h-full overflow-y-auto">
    <!-- Content -->
  </div>

  <!-- Tab Bar -->
  <div class="absolute bottom-[34px] left-0 right-0 h-[85px]">
    <!-- Tabs -->
  </div>

  <!-- Home Indicator -->
  <div class="absolute bottom-0 left-0 right-0 h-[34px]">
    <!-- Indicator -->
  </div>
</div>
```

### Step 5.3: Add Components with Exact Styling

Implement each component using the extracted measurements:

```html
<!-- Person Row Component -->
<div class="flex items-center h-[30px]">
  <!-- Avatar -->
  <div class="w-[30px] h-[30px] bg-[#F0516D]/65 rounded-full flex items-center justify-center">
    <span class="text-white text-[10.5px] font-extrabold">JD</span>
  </div>

  <!-- Name -->
  <span class="ml-[15px] text-[15px] leading-[20px] font-bold text-[#0C0F1A]">
    Joel Drotleff
  </span>
</div>
```

### Step 5.4: Handle Complex List Layouts

For inbox-style layouts with multiple elements per row:

```jsx
{/* Message Row Structure */}
<div class="flex items-start">
  {/* Unread indicator column */}
  <div class="w-[16px] flex items-center justify-center pt-[42px]">
    {message.isUnread && (
      <div class="w-[8px] h-[8px] bg-[#0076E0] rounded-full" />
    )}
  </div>

  {/* Thumbnail */}
  <div class="w-[60px] h-[80px] flex-shrink-0 bg-gray-200 rounded-[8px] my-[15px] overflow-hidden">
    <img src={message.thumbnail} alt="" class="w-full h-full object-cover" />
  </div>

  {/* Content area with stacked layout */}
  <div class="flex-1 px-[15px] py-[15px]">
    {/* Recipients with avatar indicators */}
    <div class="flex items-center gap-[4px] mb-[5px]">
      {/* Overlapping avatars */}
      <div class="flex -space-x-[4px]">
        {message.avatars.map((avatar, i) => (
          <div
            key={i}
            class={`w-[14px] h-[14px] rounded-full flex items-center justify-center ${
              i > 0 ? "ring-1 ring-white" : ""
            }`}
            style={`background-color: ${avatar.color};`}
          >
            <span class="text-white text-[4.9px] font-extrabold">
              {avatar.initials}
            </span>
          </div>
        ))}
      </div>
      <span class="text-[12px] leading-[14px] font-semibold">
        {message.participants?.join(", ") || message.sender}
      </span>
    </div>

    {/* Subject line with timestamp */}
    <div class="flex items-center justify-between mb-[5px]">
      <h3 class="text-[16px] leading-[20px] font-extrabold truncate flex-1 mr-[10px]">
        {message.subject}
      </h3>
      <span class="text-[12px] leading-[14px] font-extrabold">
        {message.timestamp}
      </span>
    </div>

    {/* Preview text */}
    <p class="text-[15px] leading-[18px] italic line-clamp-2">
      {message.preview}
    </p>
  </div>
</div>
```

**Key techniques for complex layouts:**
- Use flexbox with `items-start` for top-aligned multi-height content
- Create fixed-width columns for indicators and thumbnails
- Use negative margins (`-space-x-[4px]`) for overlapping elements
- Apply `ring` utilities for borders on overlapping elements
- Use `line-clamp-2` for truncating preview text

### Step 5.5: Position Floating Action Buttons

For floating action buttons (FABs), use fixed positioning with proper offsets:

```jsx
{/* Floating Action Button */}
<div class="fixed bottom-[108px] right-[20px]">
  <button
    type="button"
    class="flex items-center gap-[8px] px-[20px] py-[12px] bg-[#0076E0] rounded-[37px] text-white"
  >
    <img
      src="/assets/icons/video-camera.svg"
      alt="New Message"
      class="w-[24px] h-[24px]"
    />
    <span class="text-[16px] leading-[20px] font-semibold">
      New Message
    </span>
  </button>
</div>
```

**FAB positioning tips:**
- Use `fixed` positioning, not `absolute`
- Account for tab bar height in `bottom` offset
- Match exact corner radius from Figma (`rounded-[37px]`)
- Export and use actual icons from Figma, don't create your own

## Common Pitfalls to Avoid

### 1. **Skipping Visual Export**

Never jump straight to node data. You WILL miss visual elements.

### 2. **Token Limit Errors**

```typescript
// ❌ DON'T request too many nodes at once
mcp__figmastrand__figma_get_file_nodes({
  ids: "id1,id2,id3,id4,id5,id6,id7,id8,id9", // Too many!
});

// ✅ DO batch intelligently
mcp__figmastrand__figma_get_file_nodes({
  ids: "parent_container_id",
  depth: 2,
});
```

### 3. **Missing Opacity Values**

Figma often separates opacity from color:

```javascript
// In Figma:
fills: [{
  opacity: 0.65,
  color: { r: 1, g: 0, b: 0, a: 1 }
}]

// In CSS:
background-color: rgba(255, 0, 0, 0.65);
```

### 4. **Ignoring Component Instances**

If a node type is "INSTANCE", get its component definition for full details.

### 5. **Adding Unrequested Design Elements**

**Never add design elements that aren't in the Figma file**, even if you think they would improve the design:

```jsx
// ❌ DON'T add elements you think are "better"
<button class="... shadow-lg">  // Shadow not in design!

// ✅ DO match Figma exactly
<button class="...">  // Only what's specified
```

### 6. **Creating Generic Icons Instead of Exporting**

Always export the actual icons from Figma rather than creating your own or using generic icon libraries:

```typescript
// ❌ DON'T create your own SVG interpretation
<svg>
  <path d="M15 10L19.553..." />  // Your interpretation
</svg>

// ✅ DO export the actual icon from Figma
mcp__figmastrand__figma_get_images({
  fileKey: "...",
  ids: "icon_node_id",
  format: "svg"
});
```

### 7. **Mishandling Multi-Frame Messages/Lists**

When implementing lists with multiple data types per row (like inbox messages), structure the data carefully:

```typescript
// For inbox-style lists with mixed content
interface Message {
  participants?: string[];  // For group messages
  sender?: string;          // For single sender
  avatars: {
    initials: string;
    color: string;
  }[];
  // ... other fields
}

// Display logic
{message.participants 
  ? message.participants.join(", ")
  : message.sender}
```

### 8. **Incorrect Font Weights and Small Text Sizes**

Pay special attention to font weights and very small text sizes in Figma:

```css
/* Common Nunito Sans font weight mappings */
.font-light { font-weight: 300; }      /* Light */
.font-normal { font-weight: 400; }     /* Regular */
.font-semibold { font-weight: 600; }   /* SemiBold */
.font-bold { font-weight: 700; }       /* Bold */
.font-extrabold { font-weight: 800; }  /* ExtraBold */
.font-black { font-weight: 900; }      /* Black */

/* For very small text (like avatar initials in mini circles) */
.text-[4.9px] { font-size: 4.9px; }    /* Exact Figma size */
.text-[10.5px] { font-size: 10.5px; }  /* Common avatar text size */
```

**Important:** Figma uses specific font weights (SemiBold, ExtraBold, Black) that map to numeric values. Always check the exact font style in Figma rather than guessing.

### 9. **Missing Font Weights in Google Fonts Import**

When using Google Fonts, ensure you load ALL font weights used in your design, including both regular and italic variants:

```html
<!-- ❌ DON'T load only bold weights -->
<link href="https://fonts.googleapis.com/css2?family=Nunito+Sans:wght@700;800;900&display=swap" rel="stylesheet">

<!-- ✅ DO load all weights used in the design -->
<link href="https://fonts.googleapis.com/css2?family=Nunito+Sans:ital,wght@0,300;0,400;0,600;0,700;0,800;0,900;1,300;1,400;1,600;1,700&display=swap" rel="stylesheet">
```

**Common font weight issues:**
- If `font-light` (300) doesn't work, check if weight 300 is loaded
- Italic text needs italic font variants (e.g., `1,300` for light italic)
- Figma's "Regular" is 400, not 500
- Always load the exact weights your design uses

**How to check what weights to load:**
1. Look at all text styles in Figma
2. Note every unique font weight used
3. Include italic variants if any text is italicized
4. Load all these weights in your font import

## Verification Checklist

Before considering the conversion complete:

- [ ] Export final result as image and compare side-by-side with Figma
- [ ] All text matches exactly (font, size, weight, color)
- [ ] Spacing is pixel-perfect (use browser dev tools to measure)
- [ ] Colors and opacity values are correct
- [ ] All interactive states work (hover, active, etc.)
- [ ] Icons and images are crisp and properly sized
- [ ] Responsive behavior matches design intent

## Quick Reference: Essential MCP Functions

```typescript
// 1. Visual Export (DO THIS FIRST!)
mcp__figmastrand__figma_get_images({ format: "png", scale: 2 });

// 2. File Structure
mcp__figmastrand__figma_get_file({ depth: 1 });

// 3. Node Details
mcp__figmastrand__figma_get_file_nodes({ ids: "...", depth: 2 });

// 4. Design Tokens
mcp__figmastrand__figma_get_file_styles({});
mcp__figmastrand__figma_get_file_components({});

// 5. Asset Export
mcp__figmastrand__figma_get_images({ format: "svg", svg_include_id: false });

// 6. Comments (if any)
mcp__figmastrand__figma_get_comments({ as_md: true });
```

## Remember

The most common mistake in Figma-to-code conversion is assuming you understand
the design from data alone. **Always export and view the image first.** Your
eyes will catch details that are easy to miss in JSON structures.
