# encoding: utf-8
  Dir.glob("Spec/Tinto/**/*").each do |file|
    require_relative file if File.file? file
  end

