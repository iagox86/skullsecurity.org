source "https://rubygems.org"

gem "jekyll", "~> 4.3.1"

group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.12"

  # Description/etc meta tags
  gem 'jekyll-seo-tag'

  gem 'jekyll-paginate'
  gem 'jekyll-sitemap'
  gem 'jekyll-redirect-from'
end

# group :development do
#   gem 'rake'
#   gem 'html-proofer'
# end

# Windows junk
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
  gem "wdm", "~> 0.1.1"
end

# Lock `http_parser.rb` gem to `v0.6.x` on JRuby builds since newer versions of
# the gem do not have a Java counterpart.
gem "http_parser.rb", "~> 0.6.0", :platforms => [:jruby]
