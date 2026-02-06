# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::WordDiffer
class TestWordDiffer < Test::Unit::TestCase
  def test_no_difference
    old_str = 'This is a test.'
    new_str = 'This is a test.'
    expected = 'This is a test.'
    assert_equal expected, PmdTester::WordDiffer.diff_words(old_str, new_str)
  end

  def test_simple_difference
    old_str = 'This is a test.'
    new_str = 'This is a simple test.'
    expected = 'This is a <ins class="differ">simple </ins>test.'
    assert_equal expected, PmdTester::WordDiffer.diff_words(old_str, new_str)
  end

  def test_deletion
    old_str = 'This is a test.'
    new_str = 'This is test.'
    expected = 'This is <del class="differ">a </del>test.'
    assert_equal expected, PmdTester::WordDiffer.diff_words(old_str, new_str)
  end

  def test_deletion_at_end
    old_str = 'This is test.'
    new_str = 'This is'
    expected = 'This is<del class="differ"> test.</del>'
    assert_equal expected, PmdTester::WordDiffer.diff_words(old_str, new_str)
  end

  def test_addition
    old_str = 'This is test.'
    new_str = 'This is a test.'
    expected = 'This is <ins class="differ">a </ins>test.'
    assert_equal expected, PmdTester::WordDiffer.diff_words(old_str, new_str)
  end

  def test_addition_at_end
    old_str = 'This is test'
    new_str = 'This is test is simple'
    expected = 'This is test<ins class="differ"> is simple</ins>'
    assert_equal expected, PmdTester::WordDiffer.diff_words(old_str, new_str)
  end

  def test_complex_difference
    old_str = 'The quick brown fox jumps over the lazy dog.'
    new_str = 'The quick red fox jumped over the lazy cat.'
    expected = 'The quick <del class="differ">brown</del><ins class="differ">red</ins> ' \
               'fox <del class="differ">jumps</del><ins class="differ">jumped</ins> over ' \
               'the lazy <del class="differ">dog</del><ins class="differ">cat</ins>.'
    assert_equal expected, PmdTester::WordDiffer.diff_words(old_str, new_str)
  end
end
