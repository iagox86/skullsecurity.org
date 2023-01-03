# Like post.rb, creates a Mastodon post but this doesn't touch the permalink
# or anything, simply generate the thread
require 'date'
require 'time'
require 'mastodon'
require 'yaml'
require 'pp'

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
puts

# Load the Mastodon config and connect
CONFIG = YAML::load_file(File.join(ENV['HOME'], '.skullsecurity.yaml'))
MAS_CLIENT = Mastodon::REST::Client.new(base_url: CONFIG['server'], bearer_token: CONFIG['token'])

date = DateTime.parse(metadata['date']).strftime("%A, %B %d, %Y @ %H:%M:%S")

# Create a post
puts
puts "Creating a Mastodon post..."
STATUS = MAS_CLIENT.create_status(
  "This is a comment thread for the archive SkullSecurity post \"#{ metadata['title'] }\" by #{ metadata['author'] }, posted on #{ date } and filed under #{ metadata['categories'].join(', ') }\n\n" +
  "https://blog.skullsecurity.org#{ metadata['permalink'] }\n\n" +
  "(Replies here will show up on the blog post; please ping #{ CONFIG['author'] } if there are formatting issues!)",

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
