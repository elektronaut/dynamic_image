# DynamicImage

DynamicImage is a Rails plugin that simplifies image uploading and processing.
No configuration is necessary, as resizing and processing is done on demand and
cached rather than on upload.

Note: This version is currently Rails 3 specific, although the final 1.0
version will also be compatible with 2.x.


## Installation

Install the gem:

    gem install dynamic_image

Add the gem to your Gemfile:

    gem 'dynamic_image'

Do the migrations:

    rails generate dynamic_image migrations
    rake db:migrate


## Getting started

Let's create a model with an image:

    class User
      belongs_to_image :mugshot
    end

Uploading files is pretty straightforward, just add a <tt>file_field</tt>
to your form and update your record as usual:

    <%= form_for @user, :html => {:multipart => true} do |f| %>
       Name:    <%= f.text_field :name %>
       Mugshot: <%= f.file_field :mugshot %>
       <%= submit_tag "Save" %>
    <% end %>

You can now use the <tt>dynamic_image_tag</tt> helper to show off your
new image:

    <% if @user.mugshot? %>
       <%= dynamic_image_tag @user.profile_picture, :size => '64x64' %>
    <% end %>


## Filters

I'm cleaning up the filters syntax, watch this space.


## Technical

The original master files are stored in the file system and identified a
SHA-1 hash of the contents. If you're familiar with the internal workings
of git, this should seem familiar.

Processing images on the fly is expensive. Therefore, page caching is enabled
by default, even in development mode. To disable page caching, add the following
line in your initializers:

 DynamicImage.page_caching = false


## History

DynamicImage was originally created in early 2006 to handle images
for the Pages CMS. It was later extracted as a Rails Engine for Rails
1.2 in 2007, which also marked the first public release as
dynamic_image_engine.

The API has remained more or less unchanged, but the internal workings
have been refactored a few times over the years, most notably dropping
the Engines dependency and transitioning from database storage to file
system.

The current version is based on an internal branch targeting Rails
2.3, and modified to work as a Rails 3 plugin. It's not directly
compatible with earlier versions, but upgrading shouldn't be more
trouble than migrating the files out of the database.


## Copyright

Copyright © 2006 Inge Jørgensen.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
