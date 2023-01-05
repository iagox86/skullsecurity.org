Powers https://www.skullsecurity.org

A pretty simple fork of Jekyll's default theme, combined with my theme from SkullSecurity

# Usage

I very much doubt anybody else will need this, but I need this for myself :)

To write a new post:

* Copy `templates/post.md` to `_posts`
* Fill in the metadata and the post - probably in Markdown
* Use `jekyll serve` to test locally

Probably I'd work in a branch, but /shrug

* When it's ready to post, run `ruby tooling/post.rb _posts/<post>` - that'll fill out the metadata then wait to send a Mastodon post
* Commit + push the new post
* Press `<enter>` on the `post.rb`, which will toot on Mastodon
* Commit + push again to enable comments
