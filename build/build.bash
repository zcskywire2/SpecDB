#!/bin/bash

# doesn't work with process substitution for some reason, so this will do
echo 'Combining specs...'
node build/gen-specs.js specs /tmp/specs.js public/sitemap.txt
[[ $1 == 'production' ]] && cssMini='csso' || cssMini='cat'
echo 'Bundling styles...'
cat src/css/*.css | $cssMini > public/all.css
echo 'Bundling scripts...'
# TODO: maybe add --noparse /tmp/specs.js but last time i tried it didn't make a noticeable difference (but mithril did)
browserify -r /tmp/specs.js:spec-data --noparse mithril --debug src/js/entry.js > public/bundle.js
if [[ $1 == 'production' ]]
then
    echo 'Compiling and minifying scripts...'
    # we have to write it to tmp first then move because doing it all at once causes babel to freak the fuck out
    # the file is truncated before babel has fully read it
    babel public/bundle.js | uglifyjs -cmo public/bundle.js
    echo 'Generating service worker...'
    sw-precache --root=public --sw-file=sw.js --static-file-globs='public/*'
    uglifyjs -cmo public/sw.js public/sw.js 2> /dev/null
fi
echo 'Build complete'
