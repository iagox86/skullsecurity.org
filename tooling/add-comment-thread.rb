require 'time'
require 'mastodon'
require 'yaml'
require 'pp'
require 'httparty'

BASE_URL = "https://www.skullsecurity.org"

POST = ARGV[0]

if POST.nil?
  $stderr.puts "Usage: ruby #{ $1 } <post file> [force]"
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

if metadata['comments_id'] && ARGV[1] != '1'
  puts "Post already has a comments_id: #{ metadata['comments_id'] }"
  puts
  puts "To update it anyways, set the second arg to '1'"
  exit
end

# Remove the comments_id for now
metadata.delete('comments_id')

# Load the Mastodon config
CONFIG = YAML::load_file(File.join(ENV['HOME'], '.skullsecurity.yaml'))

# Generate the status
STATUS = "New #security #blog post on #SkullSecurity by #{ CONFIG['author'] }: #{ metadata['title'] }, filed under #{ metadata['categories'].map { |s| "\##{s}" }.join(', ') }\n\n" +
  "#{BASE_URL}#{ metadata['permalink'] }\n\n" +
  "(Replies here will show up on the blog post)"

puts "Here's what the post will look like:"
puts
puts '---'
puts STATUS
puts '---'
puts

puts "Press <enter> if you're sure!"
$stdin.flush
$stdin.gets


puts "Creating a Mastodon post..."
RESPONSE = HTTParty.post(
  "#{ CONFIG['server'] }/api/v1/statuses",
  :body => {
    :status => STATUS,
    :visibility => 'unlisted',
  }.to_json,
  :headers => {
    'Authorization' => "Bearer " + CONFIG['token'],
    'Content-Type' => 'application/json',
  },
)

if RESPONSE.success?
  puts "Status successfully posted!"

  BODY = RESPONSE.parsed_response

  # Finish filling out the metadata with the status id
  puts "Done! Status = #{ BODY['id'] }!"
  metadata['comments_id'] = BODY['id']

  File.write(POST, "#{ metadata.to_yaml }\n---\n#{ post.join("\n") }\n")

  puts
  puts "Updated metadata:"
  pp metadata
else
  puts "Something went wrong!"

  pp RESPONSE
end
