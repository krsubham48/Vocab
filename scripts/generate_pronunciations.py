"""Shared ARPAbet-to-simple-phonetic-spelling conversion, backed by the
CMU Pronouncing Dictionary: the copy bundled with ko_speech_tools if that is
installed, otherwise the `cmudict` package (`pip install cmudict`).
"""
import re

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

# Consonant sequences an English syllable can start with.
ONSETS = {(c,) for c in "B CH D DH F G HH JH K L M N P R S SH T TH V W Y Z ZH".split()}
ONSETS |= {tuple(c.split()) for c in (
    "P R,B R,T R,D R,K R,G R,F R,TH R,SH R,P L,B L,K L,G L,F L,S L,"
    "S P,S T,S K,S M,S N,S F,S W,K W,G W,T W,D W,TH W,S P R,S T R,S K R,S P L,S K W,"
    "P Y,B Y,F Y,V Y,K Y,G Y,M Y,HH Y,S P Y,S K Y"
).split(",")}

# Short vowels. When stressed they take the following consonant ("LEHV-uhl", not "LEH-vuhl").
CHECKED_VOWELS = {"AE", "AH", "EH", "IH", "UH"}

_dict = None


def _dictionary():
    """word -> list of space-separated ARPAbet strings, loaded on first use."""
    global _dict
    if _dict is None:
        try:
            from ko_speech_tools.g2p.cmudict import CMUDict
            _dict = CMUDict()
        except ImportError:
            import cmudict
            _dict = {word: [" ".join(p) for p in prons] for word, prons in cmudict.dict().items()}
    return _dict


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
    dictionary = _dictionary()
    if key not in dictionary:
        return None
    return respell(dictionary[key][0].split())


def _move_r_to_stressed_syllable(phonemes):
    """"corrode" is said "kuh-ROHD", not "ker-OHD": before a stressed vowel the
    r of an unstressed "er" starts that syllable."""
    result = []
    for phoneme, following in zip(phonemes, phonemes[1:] + [""]):
        stressed_vowel = following[:-1] in VOWELS and following[-1:] in ("1", "2")
        result += ["AH0", "R"] if phoneme == "ER0" and stressed_vowel else [phoneme]
    return result


def respell(phonemes):
    """Spell a list of ARPAbet phonemes as syllables, stressed one in capitals."""
    phonemes = _move_r_to_stressed_syllable(list(phonemes))
    vowel_idx = [i for i, p in enumerate(phonemes) if _strip_stress(p)[0] in VOWELS]
    if not vowel_idx:
        return _syllable_to_text(phonemes)

    bounds = []
    prev = 0
    for k, vi in enumerate(vowel_idx):
        if k == len(vowel_idx) - 1:
            end = len(phonemes)
        else:
            cluster = [_strip_stress(p)[0] for p in phonemes[vi + 1:vowel_idx[k + 1]]]
            # Give the next syllable as many consonants as can start one.
            coda = next(n for n in range(len(cluster) + 1)
                        if n == len(cluster) or tuple(cluster[n:]) in ONSETS)
            vowel, stress = _strip_stress(phonemes[vi])
            if cluster and coda == 0 and vowel in CHECKED_VOWELS and stress != "0":
                coda = 1
            end = vi + 1 + coda
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
