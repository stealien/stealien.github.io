#/bin/sh

git checkout master
rm -rf _site/
bundle exec jekyll build

if [ $? -eq 0 ]; then
    rm -rf docs/
    mv _site docs
else
    echo "[x] jekyll build failed .."

git add --all
git commit -m "`date`"
git push origin master
