# encoding: utf-8
$:.unshift File.expand_path('../../../Lib', __FILE__)
require 'minitest/autorun'
require_relative '../../Lib/Tinto/Sanitizer'

describe Tinto::Sanitizer do

  describe '.sanitize' do end # .sanitize no specs pointless

  describe '.sanitize_hash' do
    before do
      @hash = {
        'key1' => 1,
        'key2' => '<foo>bar</foo>',
        key3: nil,
        key4: '<img src="img.jpg" onload="some_script" />',
        'key5' => {
          'key1' => 1,
          'key2' => '<foo>bar</foo>',
          key3: nil,
          key4: '<img src="img.jpg" onload="some_script" />'
        },
        key6: {
          'key1' => 1,
          'key2' => '<foo>bar</foo>',
          key3: nil,
          key4: '<img src="img.jpg" onload="some_script" />'
        }
      }
    end

    it 'return empty hash if the argument is not a Hash' do
      output = Tinto::Sanitizer.sanitize_hash(nil)
      output.must_be_kind_of Hash
      output.must_be_empty

      output = Tinto::Sanitizer.sanitize_hash('string')
      output.must_be_kind_of Hash
      output.must_be_empty
    end

    it 'return the sanitized hash' do
      output = Tinto::Sanitizer.sanitize_hash(@hash)
      output.wont_equal @hash
      output.keys.must_equal @hash.keys
      output['key2'].must_equal 'bar'
      output[:key4].wont_include 'onload'
      output['key5']['key2'].must_equal 'bar'
      output['key5'][:key4].wont_include 'onload'
      output[:key6]['key2'].must_equal 'bar'
      output[:key6][:key4].wont_include 'onload'
    end
  end # .sanitize_hash
  
  describe '.sanitize_hash2json' do
    before do
      @hash = {
        'key1' => 1,
        'key2' => '<foo>bar</foo>',
        key3: nil,
        key4: '<img src="img.jpg" onload="some_script" />',
        'key5' => {
          'key1' => 1,
          'key2' => '<foo>bar</foo>',
          key3: nil,
          key4: '<img src="img.jpg" onload="some_script" />'
        },
        key6: {
          'key1' => 1,
          'key2' => '<foo>bar</foo>',
          key3: nil,
          key4: '<img src="img.jpg" onload="some_script" />'
        }
      }
    end

    it "return the sanitized json string" do
      result = Tinto::Sanitizer.sanitize_hash2json(@hash)
      result.must_be_kind_of String
      parsed_result = JSON.parse(result)
      parsed_result.must_be_kind_of Hash
    end
  end # .sanitize_hash2json
  
end # Tinto::Sanitizer
