require "twostroke"

output = nil

def time(name)
end

def pretty(obj)
  red = `tput setaf 1`
  green = `tput setaf 2`
  yellow = `tput setaf 3`
  pink = `tput setaf 5`
  blue = `tput setaf 6`
  reset = `tput sgr0`

  obj.pretty_inspect
    .gsub(/<([A-Z][a-zA-Z]*(::[A-Za-z][A-Za-z]*)*)/) { |m| "<#{red}#{$1}#{reset}" }
    .gsub(/([^:])(:[a-z]+)/i) { |m| "#{$1}#{pink}#{$2}#{reset}" }
    .gsub(/"([^"]+)"/) { |m| "#{green}\"#{$1}\"#{reset}" }
    .gsub(/=([\d\.\d]+)/) { |m| "=#{yellow}#{$1}#{reset}" }
    .gsub(/(@[a-z_][a-z_0-9]*)/i) { |m| "#{blue}#{$1}#{reset}" }
end

lexer = Twostroke::Lexer.new(File.read ARGV.first)
if ARGV.includes? "--tokens"
elsif ARGV.includes? "--bench"
else
  parser = Twostroke::Parser.new lexer
  parser.parse
  output = parser.statements
end

puts pretty(output)
