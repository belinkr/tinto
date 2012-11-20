# encoding: utf-8
$:.unshift File.expand_path('Lib')
group :tinto do
  guard :minitest, test_folders: ["Spec/Tinto"], 
  test_file_patterns: ["*Spec.rb"] do
    watch(%r|^Tinto/(.*)/(.*)\.rb|) { |matches| 
      "Spec/#{matches[1]}/#{matches[2]}Spec.rb" 
    }
    watch(%r|^Lib/Tinto/(.*)/(.*)/(.*)\.rb|) { |matches| 
      "Spec/#{matches[1]}/#{matches[2]}/#{matches[3]}Spec.rb" 
    }
    watch(%r|^Spec/Tinto/(.*)/(.*)Spec\.rb|)
  end
end

notification :tmux, 
  display_message: true,

  # in seconds
  timeout: 5, 

  # the first %s will show the title, the second the message
  # Alternately you can also configure *success_message_format*,
  # *pending_message_format*, *failed_message_format*
  default_message_format: '%s >> %s',

  # since we are single line we need a separator
  line_separator: ' > ', 

  # to customize which tmux element will change color
  color_location: 'status-left-bg'

