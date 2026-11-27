"""Builds the iOS Advanced deck from the original word list in scripts/advanced_words/.

Usage:  python3 scripts/generate_ios_advanced_deck.py [--report]
Needs a CMU dictionary (`pip install cmudict`, see generate_pronunciations.py).
`--report` also lists words the dictionary pronounces in more than one way.

The list is original to Vocab. Every check below fails the build rather than
writing a deck with a duplicate, a gap or a missing pronunciation.
"""
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import generate_pronunciations as pronunciations
from everyday_words_raw import EVERYDAY_WORDS

SOURCE = Path(__file__).parent / "advanced_words"
OUTPUT = Path(__file__).parent.parent / "ios/Vocab/Resources/words-advanced.json"
PARTS_OF_SPEECH = {"n": "noun", "v": "verb", "adj": "adjective", "adv": "adverb"}

# ARPAbet for words the dictionary lacks, or whose first entry is for a
# different use of the word from the one taught here.
PHONEMES = {
    "abstemious": "AE0 B S T IY1 M IY0 AH0 S",
    "amenable": "AH0 M IY1 N AH0 B AH0 L",
    "annex": "AH0 N EH1 K S",
    "antecedent": "AE2 N T AH0 S IY1 D AH0 N T",
    "august": "AO0 G AH1 S T",
    "autodidact": "AO2 T OW0 D AY1 D AE2 K T",
    "avaricious": "AE2 V ER0 IH1 SH AH0 S",
    "capitulate": "K AH0 P IH1 CH AH0 L EY2 T",
    "circumlocution": "S ER2 K AH0 M L OW0 K Y UW1 SH AH0 N",
    "conciliate": "K AH0 N S IH1 L IY0 EY2 T",
    "confound": "K AH0 N F AW1 N D",
    "covetous": "K AH1 V AH0 T AH0 S",
    "degenerate": "D IH0 JH EH1 N ER0 EY2 T",
    "dexterous": "D EH1 K S T ER0 AH0 S",
    "diffident": "D IH1 F AH0 D AH0 N T",
    "dilettante": "D IH1 L AH0 T AA2 N T",
    "disconsolate": "D IH0 S K AA1 N S AH0 L AH0 T",
    "enervate": "EH1 N ER0 V EY2 T",
    "entreat": "EH0 N T R IY1 T",
    "excise": "EH1 K S AY2 Z",
    "expatriate": "EH0 K S P EY1 T R IY0 AH0 T",
    "fecund": "F EH1 K AH0 N D",
    "foliage": "F OW1 L IY0 IH0 JH",
    "hedonist": "HH IY1 D AH0 N IH0 S T",
    "impasse": "IH1 M P AE0 S",
    "impermeable": "IH0 M P ER1 M IY0 AH0 B AH0 L",
    "imperturbable": "IH2 M P ER0 T ER1 B AH0 B AH0 L",
    "importune": "IH2 M P AO0 R T UW1 N",
    "impudent": "IH1 M P Y AH0 D AH0 N T",
    "malapropism": "M AE1 L AH0 P R AA2 P IH2 Z AH0 M",
    "mellifluous": "M AH0 L IH1 F L UW0 AH0 S",
    "munificent": "M Y UW0 N IH1 F AH0 S AH0 N T",
    "neologism": "N IY0 AA1 L AH0 JH IH2 Z AH0 M",
    "nonplus": "N AA2 N P L AH1 S",
    "palliate": "P AE1 L IY0 EY2 T",
    "panegyric": "P AE2 N AH0 JH IH1 R IH0 K",
    "plutocracy": "P L UW0 T AA1 K R AH0 S IY0",
    "polymath": "P AA1 L IY0 M AE2 TH",
    "propitiate": "P R OW0 P IH1 SH IY0 EY2 T",
    "qualm": "K W AA1 M",
    "rapacious": "R AH0 P EY1 SH AH0 S",
    "rebuke": "R IH0 B Y UW1 K",
    "remonstrate": "R IH0 M AA1 N S T R EY2 T",
    "reverberate": "R IH0 V ER1 B ER0 EY2 T",
    "sagacious": "S AH0 G EY1 SH AH0 S",
    "sallow": "S AE1 L OW0",
    "salubrious": "S AH0 L UW1 B R IY0 AH0 S",
    "sermonize": "S ER1 M AH0 N AY2 Z",
    "sinecure": "S AY1 N AH0 K Y UH2 R",
    "sycophant": "S IH1 K AH0 F AE2 N T",
    "tautology": "T AO0 T AA1 L AH0 JH IY0",
    "transfigure": "T R AE0 N S F IH1 G Y ER0",
    "transmute": "T R AE0 N Z M Y UW1 T",
    "vainglorious": "V EY2 N G L AO1 R IY0 AH0 S",
    "verbose": "V ER0 B OW1 S",
    "wheedle": "W IY1 D AH0 L",
}


def read_entries():
    entries = []
    for path in sorted(SOURCE.glob("*.txt")):
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if not line.strip() or line.startswith("#"):
                continue
            where = f"{path.name}:{number}"
            fields = [field.strip() for field in line.split("|")]
            if len(fields) != 4 or not all(fields) or fields[1] not in PARTS_OF_SPEECH:
                raise SystemExit(f"{where}: expected word|n/v/adj/adv|definition|example")
            head, pos, definition, example = fields
            meaning = {"partOfSpeech": PARTS_OF_SPEECH[pos], "definition": definition, "example": example}
            if head == "+":
                entries[-1]["meanings"].append(meaning)
            else:
                entries.append({"word": head.lower(), "meanings": [meaning], "where": where})
    return entries


def uses(word, example):
    """True if the example contains the word, allowing for endings like -ed or -ies."""
    stem = word[: max(4, len(word) - 3)]
    return re.search(rf"\b{re.escape(stem)}", example, re.IGNORECASE) is not None


def problems_in(entries):
    everyday = {entry["word"].lower() for entry in EVERYDAY_WORDS}
    seen, problems = {}, []
    for entry in entries:
        word, where = entry["word"], entry["where"]
        if word in seen:
            problems.append(f"{where}: '{word}' repeats {seen[word]}")
        seen.setdefault(word, where)
        if word in everyday:
            problems.append(f"{where}: '{word}' is already in the Everyday deck")
        for meaning in entry["meanings"]:
            if re.search(rf"\b{re.escape(word)}\b", meaning["definition"], re.IGNORECASE):
                problems.append(f"{where}: '{word}' is used in its own definition")
            if not uses(word, meaning["example"]):
                problems.append(f"{where}: example does not use '{word}'")
    return problems


def pronounce(word):
    if word in PHONEMES:
        return pronunciations.respell(PHONEMES[word].split())
    return pronunciations.pronounce(word)


def report_variants(entries):
    dictionary = pronunciations._dictionary()
    for entry in entries:
        word = entry["word"]
        if word in PHONEMES or word not in dictionary:
            continue
        variants = list(dict.fromkeys(pronunciations.respell(p.split()) for p in dictionary[word]))
        if len(variants) > 1:
            print(f"  {word} ({entry['meanings'][0]['partOfSpeech']}): {' / '.join(variants)}")


def main():
    entries = read_entries()
    problems = problems_in(entries)
    missing = [entry["word"] for entry in entries if pronounce(entry["word"]) is None]
    if "--report" in sys.argv:
        print("pronounced in more than one way:")
        report_variants(entries)
    print(f"{len(entries)} words")
    if missing:
        print(f"no pronunciation for {len(missing)}: {' '.join(missing)}")
    for problem in problems:
        print(problem)
    if problems or missing:
        raise SystemExit("deck not written")

    deck = [{"id": e["word"], "word": e["word"].capitalize(), "pronunciation": pronounce(e["word"]),
             "deck": "advanced", "meanings": e["meanings"]}
            for e in sorted(entries, key=lambda e: e["word"])]
    OUTPUT.write_text(json.dumps(deck, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {OUTPUT}")


if __name__ == "__main__":
    main()
