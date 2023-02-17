require 'time'
require 'yaml'
require 'pp'

BASE_URL = "https://www.skullsecurity.org"

POST = ARGV[0]

if POST.nil?
  $stderr.puts "Usage: ruby #{$1} <post file> [force]"
  exit 1
end

# Split the file at newlines
post = File.read(POST).split(/\n/)

# Ensure it has a proper metadata section
if post.shift != '---'
  $stderr.puts "Missing --- on first line"
  exit 1
end

# Get the metadata section
metadata = []
while post[0] != '---'
  metadata << post.shift

  if post.length == 0
    $stderr.puts "Missing '---' after metadata"
    exit 1
  end
end

# Remove the '---'
post.shift

# Parse and fill out the metadata as much as we can
metadata = YAML::load(metadata.join("\n"))

if !metadata
  $stderr.puts "Could not parse metadata:"
  $stderr.puts
  $stderr.puts metadata.join("\n")
  exit 1
end

puts "Original Metadata:"
pp metadata

if metadata['permalink'] && ARGV[1] != '1'
  $stderr.puts "Already has a permalink, set the second arg to '1' to force: #{ metadata['permalink'] }"
  exit
end

permalink_name = metadata['title'].downcase.gsub(/[^0-9a-zA-Z_.-]/, '-')
metadata['permalink'] = "/#{ Time.now.year }/#{ permalink_name }"

File.write(POST, "#{ metadata.to_yaml }\n---\n#{ post.join("\n") }\n")

puts
puts "Updated Metadata:"
pp metadata
