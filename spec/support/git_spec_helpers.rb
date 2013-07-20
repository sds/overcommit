module GitSpecHelpers
  def repo(&block)
    Dir.mktmpdir.tap do |path|
      Dir.chdir(path) do
        `git init`
        block.call
      end
    end
  end

  extend self
end
