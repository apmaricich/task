// ANSI escape sequence parser and converter to SolidJS text attributes

// Standard 16-color terminal palette
const COLORS: Record<number, string> = {
  30: "black",
  31: "red",
  32: "green",
  33: "yellow",
  34: "blue",
  35: "magenta",
  36: "cyan",
  37: "white",
  90: "black",
  91: "red",
  92: "green",
  93: "yellow",
  94: "blue",
  95: "magenta",
  96: "cyan",
  97: "white",
};

const BG_COLORS: Record<number, string> = {
  40: "black",
  41: "red",
  42: "green",
  43: "yellow",
  44: "blue",
  45: "magenta",
  46: "cyan",
  47: "white",
  100: "black",
  101: "red",
  102: "green",
  103: "yellow",
  104: "blue",
  105: "magenta",
  106: "cyan",
  107: "white",
};

// Style attributes for SolidJS text component
import {
  bold,
  italic,
  underline,
  dim,
  fg,
  bg,
  black,
  red,
  green,
  yellow,
  blue,
  magenta,
  cyan,
  white,
  brightBlack,
  brightRed,
  brightGreen,
  brightYellow,
  brightBlue,
  brightMagenta,
  brightCyan,
  brightWhite,
  type TextChunk,
} from "@opentui/core";

export interface TextStyle {
  fg?: string;
  bg?: string;
  bold?: boolean;
  underline?: boolean;
  italic?: boolean;
  dim?: boolean;
}

export interface StyledSegment {
  text: string;
  style?: TextStyle;
}

export function segmentToChunk(seg: StyledSegment): TextChunk {
  let chunk: TextChunk = { __isChunk: true, text: seg.text };
  if (seg.style) {
    if (seg.style.bold) chunk = bold(chunk);
    if (seg.style.italic) chunk = italic(chunk);
    if (seg.style.underline) chunk = underline(chunk);
    if (seg.style.dim) chunk = dim(chunk);
    if (seg.style.fg) chunk = fg(seg.style.fg)(chunk);
    if (seg.style.bg) chunk = bg(seg.style.bg)(chunk);
  }
  return chunk;
}

/**
 * Parse ANSI escape sequences into styled text segments.
 * Each segment represents a contiguous piece of text with the same style.
 */
export function parseAnsi(input: string): StyledSegment[] {
  const segments: StyledSegment[] = [];
  let currentStyle: TextStyle = {};
  let currentText = "";
  let i = 0;

  while (i < input.length) {
    if (input[i] === "\x1b" && input[i + 1] === "[") {
      // Found an ANSI escape sequence
      // Flush the current segment if there's text
      if (currentText) {
        if (Object.keys(currentStyle).length > 0) {
          segments.push({ text: currentText, style: { ...currentStyle } });
        } else {
          segments.push({ text: currentText });
        }
        currentText = "";
      }

      // Parse the escape sequence
      let j = i + 2;
      while (j < input.length && !isTerminalChar(input[j])) {
        j++;
      }
      const seq = input.slice(i + 2, j);
      j++; // Skip the terminal character

      // Handle reset (0)
      if (seq === "0") {
        currentStyle = {};
      } else if (seq === "") {
        // SGR with no parameters = reset
        currentStyle = {};
      } else {
        // Parse multiple codes separated by ;
        const codes = seq.split(";").filter((c) => c !== "");
        for (const code of codes) {
          const num = parseInt(code, 10);
          if (num >= 30 && num <= 37) {
            currentStyle.fg = COLORS[num];
          } else if (num >= 90 && num <= 97) {
            currentStyle.fg = COLORS[num];
          } else if (num >= 40 && num <= 47) {
            currentStyle.bg = BG_COLORS[num];
          } else if (num >= 100 && num <= 107) {
            currentStyle.bg = BG_COLORS[num];
          } else if (num === 1) {
            currentStyle.bold = true;
          } else if (num === 4) {
            currentStyle.underline = true;
          } else if (num === 3) {
            currentStyle.italic = true;
          } else if (num === 2) {
            currentStyle.dim = true;
          } else if (num === 22) {
            currentStyle.bold = false;
            currentStyle.dim = false;
          } else if (num === 24) {
            currentStyle.underline = false;
          } else if (num === 23) {
            currentStyle.italic = false;
          } else if (num === 39) {
            delete currentStyle.fg;
          } else if (num === 49) {
            delete currentStyle.bg;
          }
        }
      }

      i = j;
    } else {
      currentText += input[i];
      i++;
    }
  }

  // Flush remaining text
  if (currentText) {
    if (Object.keys(currentStyle).length > 0) {
      segments.push({ text: currentText, style: { ...currentStyle } });
    } else {
      segments.push({ text: currentText });
    }
  }

  return segments;
}

function isTerminalChar(char: string): boolean {
  const code = char.charCodeAt(0);
  return code >= 64 && code <= 126; // @ to ~
}
