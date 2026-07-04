#!/usr/bin/env ruby
# frozen_string_literal: true

ROOT = File.expand_path("..", __dir__)
SITE = File.join(ROOT, "_site")

EXPECTED_OUTPUTS = %w[
  index.html
  contact/index.html
  pub/index.html
  css/main.css
].freeze

UNPUBLISHED_OUTPUTS = %w[
  Gemfile
  LICENSE
  README.md
  scripts
].freeze

PRIVATE_PATTERNS = {
  "direct CMU email address" => /[a-z0-9._%+-]+@cs\.cmu\.edu/i,
  "obfuscated CMU email address" => /\båt\b.*cmu/i,
  "email label" => /\bEmail\s*:/i,
  "LinkedIn profile" => /linkedin\.com\/in\//i,
  "X/Twitter profile" => %r{\bx\.com/JunweiHuan}i,
  "social media section" => /Social Media/i,
  "Google Analytics snippet" => /GoogleAnalyticsObject|analytics\.js|ga\('create'/i,
  "legacy MathJax CDN" => /cdn\.mathjax\.org/i
}.freeze

def fail_with(message)
  warn "built site check failed: #{message}"
  exit 1
end

fail_with("_site directory is missing") unless Dir.exist?(SITE)

missing = EXPECTED_OUTPUTS.reject { |path| File.file?(File.join(SITE, path)) }
fail_with("missing output files: #{missing.join(", ")}") unless missing.empty?

published_extras = UNPUBLISHED_OUTPUTS.select { |path| File.exist?(File.join(SITE, path)) }
fail_with("maintenance files published: #{published_extras.join(", ")}") unless published_extras.empty?

html = %w[index.html contact/index.html pub/index.html].map do |path|
  File.read(File.join(SITE, path))
end.join("\n")

PRIVATE_PATTERNS.each do |label, pattern|
  fail_with("found #{label}") if html.match?(pattern)
end

expected_links = [
  '<a href="/">About</a>',
  '<a href="/contact/">Contact</a>',
  '<a href="/pub/">Publications</a>'
]
expected_links.each do |link|
  fail_with("missing nav link #{link}") unless html.include?(link)
end

fail_with("site title must link to local root") unless html.match?(/<a id="author-name"[^>]+href="\/"/)

%w[Multimodal ICML ICASSP GitHub Scholar].each do |term|
  fail_with("missing rendered content term #{term}") unless html.include?(term)
end

css = File.read(File.join(SITE, "css/main.css"))
fail_with("compiled CSS is empty") if css.strip.empty?

puts "built site check passed"
