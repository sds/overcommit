# Strips off excess leading indentation from each line so we can use Heredocs
# for writing code without having the leading indentation count.
module IndentNormalizer
  def normalize_indent(code)
    leading_indent = code[/^(\s*)/, 1]
    code.lstrip.gsub(/\n#{leading_indent}/, "\n")
  end
end

RSpec.configure do |_config|
  include IndentNormalizer
end
