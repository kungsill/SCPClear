//! Thai line breaking (SCP edition). Thai is written without spaces between words, so UAX #14 alone
//! offers no break inside a sentence and a paragraph only wrapped at the spaces the writer left
//! between phrases. ICU4X's dictionary segmenter (Unicode Consortium, compiled-in word list) finds
//! the word boundaries; this module hands them to the paragraph layout as break opportunities.
//! The dictionary never offers a break before a tone mark, a vowel above or below, ๆ or ฯ.

use icu_segmenter::LineSegmenter;
use icu_segmenter::options::LineBreakOptions;

/// Thai letters, vowels, tone marks and digits (U+0E01..U+0E5B).
pub fn is_thai(c: char) -> bool {
    matches!(u32::from(c), 0x0E01..=0x0E5B)
}

/// Does `text` hold any Thai? Cheap test that keeps the segmenter off other languages.
pub fn has_thai(text: &str) -> bool {
    text.chars().any(is_thai)
}

/// Line-break opportunities next to Thai text: byte offsets in `text`, sorted. Only breaks with a
/// Thai character on at least one side are returned; everything else stays with UAX #14.
pub fn breaks(text: &str) -> Vec<usize> {
    if !has_thai(text) {
        return Vec::new();
    }
    let segmenter = LineSegmenter::new_dictionary(LineBreakOptions::default());
    let mut out = Vec::new();
    for i in segmenter.segment_str(text) {
        if i == 0 || i >= text.len() {
            continue;
        }
        let before = text.get(..i).and_then(|t| t.chars().next_back());
        let after = text.get(i..).and_then(|t| t.chars().next());
        if before.is_some_and(is_thai) || after.is_some_and(is_thai) {
            out.push(i);
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn pieces(s: &str) -> Vec<&str> {
        let at = breaks(s);
        let mut v = Vec::new();
        let mut from = 0;
        for &i in &at {
            v.push(&s[from..i]);
            from = i;
        }
        v.push(&s[from..]);
        v
    }

    #[test]
    fn a_thai_sentence_without_spaces_gets_word_breaks() {
        // "ประเทศไทยเป็นประเทศที่สวยงาม": ประเทศไทย | เป็น | ประเทศ | ที่ | สวยงาม
        let p = pieces("ประเทศไทยเป็นประเทศที่สวยงาม");
        assert!(p.len() >= 4, "{p:?}");
        assert!(p.contains(&"เป็น") && p.contains(&"สวยงาม"), "{p:?}");
    }

    #[test]
    fn no_break_inside_a_word_or_before_a_mark() {
        let text = "โรงพยาบาลสีชมพูให้บริการประชาชน";
        for &i in &breaks(text) {
            let next = text[i..].chars().next().unwrap();
            // never before a tone mark, a vowel above/below, the maiyamok or the paiyannoi
            assert!(!matches!(u32::from(next), 0x0E31 | 0x0E34..=0x0E3A | 0x0E47..=0x0E4E | 0x0E46 | 0x0E2F), "break before U+{:04X} at {i}", u32::from(next));
        }
        // "สีชมพู" (pink) and "ประชาชน" (the public) are single words: no break inside them
        let p = pieces(text);
        assert!(p.contains(&"สีชมพู") && p.contains(&"ประชาชน"), "{p:?}");
    }

    #[test]
    fn text_without_thai_is_left_to_uax14() {
        assert!(breaks("A plain English sentence, 1,250.50").is_empty());
    }

    #[test]
    fn thai_next_to_latin_may_break_at_the_edge() {
        let text = "ใช้Wordหรือ Excel";
        assert!(!breaks(text).is_empty(), "{:?}", pieces(text));
    }
}
