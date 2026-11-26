"""Run with: python3 -m unittest discover -s scripts

Phonemes are copied from the CMU dictionary, so no dictionary is needed here.
"""
import unittest

from generate_pronunciations import respell


class RespellTest(unittest.TestCase):
    def check(self, phonemes, expected):
        self.assertEqual(respell(phonemes.split()), expected)

    def test_a_lone_consonant_starts_the_next_syllable(self):
        self.check("OW2 V ER0 W EH1 L M D", "oh-ver-WEHLMD")  # overwhelmed
        self.check("R AH0 F AO1 R M", "ruh-FAWRM")  # reform
        self.check("IH2 N F L EY1 SH AH0 N", "ihn-FLAY-shuhn")  # inflation

    def test_a_stressed_short_vowel_keeps_the_consonant_after_it(self):
        self.check("B AH1 JH IH0 T", "BUHJ-iht")  # budget
        self.check("L EH1 V AH0 L", "LEHV-uhl")  # level
        self.check("R IH0 Z IH1 L Y AH0 N T", "rih-ZIHL-yuhnt")  # resilient

    def test_a_syllable_never_starts_with_sounds_english_cannot_start_with(self):
        self.check("AE1 NG K SH AH0 S", "ANGK-shuhs")  # anxious
        self.check("IH0 G Z AO1 S T IH0 D", "ihg-ZAW-stihd")  # exhausted

    def test_consonant_clusters_that_can_start_a_syllable_stay_together(self):
        self.check("AA2 N T R AH0 P R AH0 N ER1", "ahn-truh-pruh-NER")  # entrepreneur
        self.check("IH1 N D AH0 S T R IY0", "IHN-duh-stree")  # industry
        self.check("K AE1 N D AH0 D", "KAN-duhd")  # candid


if __name__ == "__main__":
    unittest.main()
