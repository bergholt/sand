# Technical and preservation notes

## Timing

`SCOREDAT.PAS` declares `TOTAL_CS = 53431`: 534.31 seconds, approximately 8:54.31. It contains 29 segments, 117 text lines, 666 word records and 22 poem lines. These are implementation counts, not a claim of symbolic intent.

`SAND.SND` has 23,562,948 bytes. At 22,050 stereo frames/s and one unsigned byte per channel, this represents 534.307210884 seconds, within one centisecond of the score duration. Raw PCM has no file header; interpretation follows the supplied `SND.PAS` comments and playback constants.

The main runtime streams this file and derives time from DMA playback. The image is generated at runtime from prepared score data. The soundtrack is an offline rendering.

## Text and encoding

- APL sources are UTF-8, with APL symbols and Danish letters.
- `SCOREDAT.PAS` explicitly identifies ISO 8859-1 text; the Pascal sources include extended single-byte characters and/or numeric character values. Preserve their bytes rather than converting the full tree automatically to UTF-8.
- `SAND.NFO`, `FILE_ID.DIZ` and `SAND.ANS` contain DOS-era byte conventions; the NFO has CP437-style block characters. Markdown documentation is UTF-8.
- `SAND.ANS` includes a SAUCE record with an internal date of `20260927` and dimensions 79 × 65. This is embedded metadata, not an independently verified public release date.
- The ZIP entries carry timestamps from 28 September 2026. These also do not establish a first publication date.

## Scope distinctions

The source includes overture-related constants and routines. Their presence alone is not proof that every routine is called by the supplied playback path. The public description therefore concentrates on the active reading, accumulation and silence mechanisms.

The Latin-designated interval is not a transcription of a third voiced inscription. The supplied voice layout is German, Danish and English. English translates material from both inscription languages.

Exergue's September 2026 note proposes modem-circuit imagery and Latin inscription sound. That note is development history. The supplied source supports a letter-sea visual field and a Latin-designated gap rather than an authenticated Latin reading.

## Images

`assets/sand-ansi-preview.png` is a new rendering of the supplied ANSI artwork, with CP437 decoding, ANSI colour attributes and an approximate terminal typeface. Its block/shade characters are drawn on a fixed grid. It is not an emulator screenshot and does not reproduce a particular VGA font exactly. `SAND.ANS` remains authoritative.

The attached Google AI Overview screenshot is excluded from the public package. It is research context rather than an artwork image or an independent historical source. No website photographs, Pixel Joint images or third-party site screenshots were copied into this package.

## Original files

The supplied executable, audio, ANSI and all sources are unmodified. `.gitattributes` disables text conversion for the imported files so that Git does not normalise their line endings. `docs/ORIGINAL-FILES.sha256` verifies their bytes.
