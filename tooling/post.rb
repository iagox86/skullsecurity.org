# Updates the metadata and creates a Mastodon post

require 'time'
require 'mastodon'
require 'yaml'
require 'pp'

BASE_URL = "https://www.skullsecurity.org/"

POST = ARGV[0]

if POST.nil?
  $stderr.puts "Usage: ruby post.rb <post file>"
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

metadata['date'] = Time.now.iso8601
permalink_name = metadata['title'].downcase.gsub(/[^0-9a-zA-Z_.-]/, '-')
metadata['permalink'] = "/#{ Time.now.year }/#{ permalink_name }"

# Remove the comments_id for now
metadata.delete('comments_id')
File.write(POST, "#{ metadata.to_yaml }\n---\n#{ post.join("\n") }\n")

puts
puts "Updated Metadata:"
pp metadata

# At this point, we have done everything we possibly can before creating the post
puts
puts "You should probably post it now (`git push`), then press <enter> to create the post and fill out the comments_id"

$stdin.flush
$stdin.gets

# Load the Mastodon config and connect
CONFIG = YAML::load_file(File.join(ENV['HOME'], '.skullsecurity.yaml'))
MAS_CLIENT = Mastodon::REST::Client.new(base_url: CONFIG['server'], bearer_token: CONFIG['token'])

# Create a post
puts
puts "Creating a Mastodon post..."
STATUS = MAS_CLIENT.create_status(
  "New #security #blog post on #SkullSecurity by #{ CONFIG['author'] }: #{ metadata['title'] } by #{ metadata['author'] }, filed under #{ metadata['categories'].join(', ') }\n\n" +
  "#{BASE_DOMAIN}#{ metadata['permalink'] }\n\n" +
  "(Replies here will show up on the blog post)",

  visibility: 'unlisted',
)

# Finish filling out the metadata with the status id
puts "Done! Status = #{ STATUS.id }!"
metadata['comments_id'] = STATUS.id

# Write back to the file
File.write(POST, "#{ metadata.to_yaml }\n---\n#{ post.join("\n") }\n")

puts
puts "Updated UPDATED metadata:"
pp metadata
