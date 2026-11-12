# Some Windows Ruby installations return no matches for Jekyll's single-directory globs.
# Share the existing build workaround with the standalone regression tests.
class << Dir
  alias_method :jekyll_original_glob, :[] unless method_defined?(:jekyll_original_glob)

  def [](*patterns)
    results = jekyll_original_glob(*patterns)
    return results unless results.empty? && patterns.length == 1

    pattern = patterns.first
    return results unless pattern.match?(/[?*\[\{]/)

    directory = File.dirname(pattern)
    return results unless File.directory?(directory)

    names = [File.basename(pattern)]
    names = names.flat_map { |name| name.include?('{_,}') ? [name.sub('{_,}', '_'), name.sub('{_,}', '')] : [name] }
    Dir.children(directory)
       .select { |entry| names.any? { |name| File.fnmatch?(name, entry) } }
       .map { |entry| File.join(directory, entry) }.sort
  end
end
