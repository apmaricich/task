import { parseAnsi, segmentToChunk } from "../src/ansi.js";
import assert from "assert";

let passed = 0;
let failed = 0;

function test(name: string, fn: () => void) {
  try {
    fn();
    passed++;
    console.log(`✓ ${name}`);
  } catch (e) {
    failed++;
    console.log(`✗ ${name}`);
    console.log(`  ${e.message}`);
  }
}

// parseAnsi tests
test("plain text has no style", () => {
  const segments = parseAnsi("Hello");
  assert.equal(segments.length, 1);
  assert.equal(segments[0].text, "Hello");
  assert.equal(segments[0].style, undefined);
});

test("bold text is parsed", () => {
  const segments = parseAnsi("\x1b[1mBold\x1b[0m");
  assert.equal(segments.length, 1);
  assert.equal(segments[0].text, "Bold");
  assert.equal(segments[0].style?.bold, true);
});

test("colored text is parsed", () => {
  const segments = parseAnsi("\x1b[34mBlue\x1b[0m");
  assert.equal(segments.length, 1);
  assert.equal(segments[0].style?.fg, "blue");
});

// segmentToChunk tests
test("plain segment becomes chunk", () => {
  const chunk = segmentToChunk({ text: "Hi" });
  assert.equal(chunk.__isChunk, true);
  assert.equal(chunk.text, "Hi");
});

test("bold segment creates styled chunk", () => {
  const chunk = segmentToChunk({ text: "B", style: { bold: true } });
  assert.equal(chunk.__isChunk, true);
  assert.ok(chunk.attributes !== undefined);
});

test("colored segment creates chunk with fg", () => {
  const chunk = segmentToChunk({ text: "B", style: { fg: "blue" } });
  assert.equal(chunk.__isChunk, true);
  assert.ok(chunk.fg !== undefined);
});

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);