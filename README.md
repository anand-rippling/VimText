# VimText

A native macOS notes app with comprehensive Vim keybinding support. Think Apple Notes, but with Vim.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

### Notes Management
- **Sidebar with note list** — browse all your notes in a clean sidebar
- **Pinned notes** — pin important notes to the top
- **Search across notes** — `Cmd+Shift+F` to search all notes by title/content, navigate results with arrow keys, press Enter to open
- **Context menus** — right-click notes for rename, pin, delete
- **Multi-select & bulk delete** — select multiple notes and delete them at once
- **Auto-save** — notes are saved automatically as you type
- **Local storage** — all notes stored as JSON in `~/Library/Application Support/VimText/`

### Vim Modes
| Mode | How to Enter |
|------|-------------|
| **Normal** | `Esc` |
| **Insert** | `i`, `a`, `o`, `O`, `A`, `I`, `s`, `S`, `c` commands |
| **Visual** | `v` |
| **Visual Line** | `Shift+V` |
| **Visual Block** | `Ctrl+V` |
| **Command** | `:` |

### Vim Keybindings

#### Navigation
| Key | Action |
|-----|--------|
| `h` `j` `k` `l` | Left, down, up, right |
| `w` `b` `e` | Word forward, word back, end of word |
| `0` `$` `^` | Line start, line end, first non-blank |
| `gg` / `G` | Document start / end |
| `{` `}` | Paragraph up / down |
| `%` | Matching bracket |
| `f`/`F` + char | Find char forward / backward |
| `t`/`T` + char | Till char forward / backward |
| `;` `,` | Repeat / reverse last f/t motion |

#### Operators
| Key | Action |
|-----|--------|
| `d` | Delete (+ motion/text object) |
| `c` | Change (+ motion/text object) |
| `y` | Yank/copy (+ motion/text object) |
| `p` / `P` | Paste after / before cursor |
| `dd` | Delete line |
| `cc` | Change line |
| `yy` | Yank line |
| `D` | Delete to end of line |
| `C` | Change to end of line |
| `x` | Delete character |
| `r` + char | Replace character |
| `~` | Toggle case |
| `s` | Substitute character |
| `S` | Substitute line |
| `J` | Join lines |
| `>>` / `<<` | Indent / outdent |

#### Operators with Counts & Motions
Combine counts and motions freely:
- `d2j` — delete current line and 2 lines below
- `3dd` — delete 3 lines
- `dG` — delete from current line to end of file
- `cgg` — change from current line to start of file
- `y3w` — yank 3 words
- `d$` — delete to end of line
- `cf)` — change up to and including `)` 
- `dt"` — delete till `"`

#### Text Objects
Use with `d`, `c`, `y`, or `v`:

| Key | Action |
|-----|--------|
| `iw` / `aw` | Inner / a word |
| `i"` / `a"` | Inner / a double-quoted string |
| `i'` / `a'` | Inner / a single-quoted string |
| `i(` / `a(` | Inner / a parenthesized block |
| `i[` / `a[` | Inner / a bracketed block |
| `i{` / `a{` | Inner / a braced block |
| `i<` / `a<` | Inner / an angle-bracketed block |
| `ip` / `ap` | Inner / a paragraph |

Examples: `ci"` (change inside quotes), `da(` (delete around parens), `yiw` (yank inner word)

#### Visual Mode
- `v` — character-wise visual selection
- `V` — line-wise visual selection
- `Ctrl+V` — block (column) visual selection
- Move with `h` `j` `k` `l` and all motions to extend selection
- `o` — swap cursor and anchor (change selection direction)
- `d` / `x` — delete selection
- `c` — change selection
- `y` — yank selection (with flash highlight)
- `>` / `<` — indent / outdent selection

#### Visual Block Mode (`Ctrl+V`)
- Select rectangular columns of text
- `I` — insert text at the start of every line in the block
- `A` — append text at the end of every line in the block
- `d` / `x` — delete the block
- `c` — change the block
- `y` — yank the block

#### Search
| Key | Action |
|-----|--------|
| `/` + pattern | Search forward |
| `?` + pattern | Search backward |
| `n` | Next match |
| `N` | Previous match |
| `Cmd+F` | Native macOS find bar (in-editor) |

Search highlights auto-clear after a short timeout.

#### Dot Repeat
- `.` — repeat the last change (delete, change, replace, insert text, etc.)

#### System Clipboard
- Yank (`y`, `yy`) copies to the macOS system clipboard
- Paste (`p`, `P`) reads from the system clipboard
- Full interop with other apps — copy in Safari, paste in VimText and vice versa

#### Other
| Key | Action |
|-----|--------|
| `u` | Undo |
| `Ctrl+R` | Redo |
| `o` / `O` | New line below / above |
| `:w` | Save |
| `Cmd+N` | New note |
| `Cmd+Shift+F` | Search across notes |

## Building

### Prerequisites
- macOS 14.0+
- Swift 5.9+ (included with Xcode Command Line Tools)

### Build & Install

```bash
# Clone the repo
git clone https://github.com/anand-rippling/VimText.git
cd VimText

# Build and install to /Applications
chmod +x build.sh
./build.sh
```

The build script will:
1. Compile a release build using Swift Package Manager
2. Create a proper `.app` bundle
3. Install it to `/Applications/VimText.app`
4. Launch the app

### Manual Build

```bash
swift build -c release
```

The binary will be at `.build/release/VimText`.

## Architecture

```
VimText/
├── Models/
│   ├── Note.swift              # Note data model
│   └── NoteFolder.swift        # Folder data model
├── Storage/
│   └── StorageManager.swift    # JSON-based local persistence
├── ViewModels/
│   └── NotesViewModel.swift    # App state & business logic
├── Views/
│   ├── ContentView.swift       # Main layout
│   ├── NoteListView.swift      # Sidebar note list & search
│   ├── NoteEditorView.swift    # Editor wrapper
│   └── NoteRowView.swift       # Individual note row
├── Vim/
│   ├── VimEngine.swift         # Core Vim state machine & key processing
│   ├── VimMode.swift           # Mode, action, motion & text object enums
│   └── VimTextView.swift       # NSTextView integration & action execution
└── VimTextApp.swift            # App entry point & global shortcuts
```

## Data Storage

Notes are stored as individual JSON files in:

```
~/Library/Application Support/VimText/notes/
```

Each note is a separate `.json` file with its content, title, timestamps, and metadata.

## License

MIT
