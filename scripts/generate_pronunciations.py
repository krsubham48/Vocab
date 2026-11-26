"""Shared ARPAbet-to-simple-phonetic-spelling conversion, backed by the
CMU Pronouncing Dictionary bundled with the locally installed ko_speech_tools
package. No network access or pip install required.
"""
import re

from ko_speech_tools.g2p.cmudict import CMUDict

VOWELS = {
    "AA", "AE", "AH", "AO", "AW", "AY", "EH", "ER", "EY",
    "IH", "IY", "OW", "OY", "UH", "UW",
}

SIMPLE = {
    "AA": "ah", "AE": "a", "AH": "uh", "AO": "aw", "AW": "ow", "AY": "ahy",
    "EH": "eh", "ER": "er", "EY": "ay", "IH": "ih", "IY": "ee", "OW": "oh",
    "OY": "oy", "UH": "uu", "UW": "oo",
    "B": "b", "CH": "ch", "D": "d", "DH": "th", "F": "f", "G": "g", "HH": "h",
    "JH": "j", "K": "k", "L": "l", "M": "m", "N": "n", "NG": "ng", "P": "p",
    "R": "r", "S": "s", "SH": "sh", "T": "t", "TH": "th", "V": "v", "W": "w",
    "Y": "y", "Z": "z", "ZH": "zh",
}

_dict = CMUDict()


def _strip_stress(phoneme):
    m = re.match(r"^([A-Z]+)([0-2])?$", phoneme)
    return m.group(1), m.group(2)


def _phoneme_to_simple(phoneme):
    base, _ = _strip_stress(phoneme)
    return SIMPLE.get(base, base.lower())


def _syllable_to_text(chunk):
    return "".join(_phoneme_to_simple(p) for p in chunk)


def pronounce(word, overrides=None):
    """Return a simple phonetic spelling like 'uh-BUN-dant', or None if the
    word isn't in the CMU dictionary and has no manual override.
    `overrides` is an optional dict of lowercase word -> pronunciation string,
    for words the dictionary doesn't cover (checked first).
    """
    key = word.lower()
    if overrides and key in overrides:
        return overrides[key]
    if key not in _dict:
        return None
    phonemes = _dict[key][0].split()
    vowel_idx = [i for i, p in enumerate(phonemes) if _strip_stress(p)[0] in VOWELS]
    if not vowel_idx:
        return _syllable_to_text(phonemes)

    bounds = []
    prev = 0
    for k, vi in enumerate(vowel_idx):
        if k == len(vowel_idx) - 1:
            end = len(phonemes)
        else:
            next_vi = vowel_idx[k + 1]
            consonants_between = next_vi - vi - 1
            if consonants_between <= 1:
                end = vi + 1 + consonants_between
            else:
                end = vi + 2
        bounds.append((prev, end))
        prev = end

    parts = []
    for (s, e) in bounds:
        chunk = phonemes[s:e]
        stress = None
        for p in chunk:
            base, st = _strip_stress(p)
            if base in VOWELS:
                stress = st
        text = _syllable_to_text(chunk)
        if stress == "1":
            text = text.upper()
        parts.append(text)
    return "-".join(parts)
