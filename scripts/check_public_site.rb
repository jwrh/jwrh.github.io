#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

ROOT = File.expand_path("..", __dir__)
REQUIRED_FILES = %w[
  _config.yml
  _layouts/default.html
  css/main.scss
  index.md
  contact.md
  pub.md
].freeze

PUBLIC_LINKS = [
  "https://github.com/jwrh",
  "https://scholar.google.com/citations?user=XDKbC3QAAAAJ"
].freeze

PRIVATE_PATTERNS = {
  "direct CMU email address" => /[a-z0-9._%+-]+@cs\.cmu\.edu/i,
  "obfuscated CMU email address" => /\[\*\*åt\*\*\].*cmu/i,
  "email label" => /\bEmail\s*:/i,
  "LinkedIn profile" => /linkedin\.com\/in\//i,
  "X/Twitter profile" => %r{\bx\.com/JunweiHuan}i,
  "social media section" => /Social Media/i,
  "Google Analytics snippet" => /GoogleAnalyticsObject|analytics\.js|ga\('create'/i,
  "placeholder tracking id" => /tracking_id:\s*#/i,
  "legacy MathJax CDN" => /cdn\.mathjax\.org/i
}.freeze

def read(path)
  File.read(File.join(ROOT, path))
end

def fail_with(message)
  warn "public site check failed: #{message}"
  exit 1
end

missing = REQUIRED_FILES.reject { |path| File.file?(File.join(ROOT, path)) }
fail_with("missing required files: #{missing.join(", ")}") unless missing.empty?

config = YAML.safe_load(read("_config.yml"), permitted_classes: [], aliases: false)
fail_with("_config.yml must set url to https://jwrh.github.io") unless config["url"] == "https://jwrh.github.io"

nav = config.fetch("nav")
expected_nav = [
  { "name" => "About", "link" => "/" },
  { "name" => "Contact", "link" => "/contact/" },
  { "name" => "Publications", "link" => "/pub/" }
]
fail_with("navigation must use root-relative pretty links") unless nav == expected_nav

site_text = REQUIRED_FILES.map { |path| read(path) }.join("\n")
PRIVATE_PATTERNS.each do |label, pattern|
  fail_with("found #{label}") if site_text.match?(pattern)
end

PUBLIC_LINKS.each do |link|
  fail_with("missing public link #{link}") unless site_text.include?(link)
end

%w[Multimodal ICML ICASSP Carnegie].each do |term|
  fail_with("lost recovered content term #{term}") unless site_text.include?(term)
end

%w[index.md contact.md pub.md].each do |path|
  front_matter = read(path).match(/\A---\n(.*?)\n---/m)
  fail_with("#{path} is missing YAML front matter") unless front_matter

  metadata = YAML.safe_load(front_matter[1], permitted_classes: [], aliases: false)
  fail_with("#{path} must use the default layout") unless metadata["layout"] == "default"
  fail_with("#{path} must declare a permalink") unless metadata["permalink"]
end

puts "public site check passed"
