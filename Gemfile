source "https://rubygems.org"

# Jekyll 4.4.x — latest stable release
gem "jekyll", "~> 4.4.0"

# Theme (kept for fallback layouts/includes)
gem "minima", "~> 2.5"

# Plugins
group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.17"
  gem "jekyll-seo-tag", "~> 2.8"
  gem "jekyll-polyglot", "~> 1.8"
end

# Windows and JRuby does not include zoneinfo files
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1.2", "< 3"
  gem "tzinfo-data"
end

# Performance-booster for watching directories on Windows
gem "wdm", "~> 0.1.1", :platforms => [:mingw, :x64_mingw, :mswin]

# Required for `jekyll serve` on Ruby 3+
gem "webrick", "~> 1.8"

# ffi 1.15.x fails on Apple Silicon — pin to 1.16+
gem "ffi", ">= 1.16.0"
