import { parseAnsi } from "./ansi";

function test(name: string, fn: () => void) {
  try {
    fn();
    console.log(`✓ ${name}`);
  } catch (err) {
    console.log(`✗ ${name}: ${err}`);
  }
}

function assertEqual(actual: any, expected: any, msg?: string) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}${msg ? ": " + msg : ""}`);
  }
}

// Test basic ANSI parsing
test("parses basic red text", () => {
  const segments = parseAnsi("\x1b[31mHello\x1b[0m");
  assertEqual(segments.length, 1);
  assertEqual(segments[0].text, "Hello");
  assertEqual(segments[0].style?.fg, "red");
});

test("parses bold text", () => {
  const segments = parseAnsi("\x1b[1mBold\x1b[0m");
  assertEqual(segments.length, 1);
  assertEqual(segments[0].style?.bold, true);
});

test("parses background color", () => {
  const segments = parseAnsi("\x1b[41mRedBG\x1b[0m");
  assertEqual(segments.length, 1);
  assertEqual(segments[0].style?.bg, "red");
});

test("parses multiple styles", () => {
  const segments = parseAnsi("\x1b[1;31;42mStyled\x1b[0m");
  assertEqual(segments.length, 1);
  assertEqual(segments[0].style?.bold, true);
  assertEqual(segments[0].style?.fg, "red");
  assertEqual(segments[0].style?.bg, "green");
});

test("parses text with mixed styles", () => {
  const segments = parseAnsi("\x1b[31mRed\x1b[0m normal \x1b[32mGreen\x1b[0m");
  assertEqual(segments.length, 3);
  assertEqual(segments[0].text, "Red");
  assertEqual(segments[0].style?.fg, "red");
  assertEqual(segments[1].text, " normal ");
  assertEqual(segments[2].text, "Green");
  assertEqual(segments[2].style?.fg, "green");
});

test("handles empty input", () => {
  const segments = parseAnsi("");
  assertEqual(segments.length, 0);
});

test("handles plain text with no ANSI", () => {
  const segments = parseAnsi("Plain text");
  assertEqual(segments.length, 1);
  assertEqual(segments[0].text, "Plain text");
});

test("handles newlines", () => {
  const segments = parseAnsi("Line1\nLine2");
  assertEqual(segments.length, 1);
  assertEqual(segments[0].text, "Line1\nLine2");
});

test("handles multiple reset codes", () => {
  const segments = parseAnsi("\x1b[31mRed\x1b[0m\x1b[32mGreen\x1b[0m");
  assertEqual(segments.length, 2);
  assertEqual(segments[0].text, "Red");
  assertEqual(segments[1].text, "Green");
});

// Test task list-like output
test("handles task list output", () => {
  const output = `\x1b[1;36mTasks\x1b[0m
  \x1b[90m⬜\x1b[0m [1] Task one
  \x1b[90m✅\x1b[0m [2] Completed task
  \x1b[31m[3]\x1b[0m Task three`;
  
  const segments = parseAnsi(output);
  // Tasks header
  assertEqual(segments[0].text, "Tasks");
  assertEqual(segments[0].style?.bold, true);
  assertEqual(segments[0].style?.fg, "cyan");
  // Newline
  assertEqual(segments[1].text, "\n  ");
  // Unchecked task icon
  assertEqual(segments[2].text, "⬜");
  assertEqual(segments[2].style?.fg, "black");
  // Task text
  assertEqual(segments[3].text, " [1] Task one\n  ");
  // Checked task icon
  assertEqual(segments[4].text, "✅");
  // Task text
  assertEqual(segments[5].text, " [2] Completed task\n  ");
  // Error task number
  assertEqual(segments[6].text, "[3]");
  assertEqual(segments[6].style?.fg, "red");
  // Task text
  assertEqual(segments[7].text, " Task three");
});

console.log("\nAll tests completed.");
