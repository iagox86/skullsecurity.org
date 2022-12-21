---
short_name: featured
name: Featured Posts
layout: default
index: 1
---

{% assign posts = site.posts | rsort: 'date' | where: 'featured', true %}

{% for post in posts limit: 15 %}
* [{{ post.title }}]({{ post.url }})
{% endfor %}
