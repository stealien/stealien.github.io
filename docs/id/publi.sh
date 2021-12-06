#/bin/sh

git checkout master

# Remove the built file.
rm -rf _site/
rm -rf docs/

# Run build
bundle exec jekyll build

if [ $? -eq 0 ]; then
    rm -rf docs/
    mv _site docs
else
    echo "[x] jekyll build failed .."
    exit
fi

git add --all
git commit -m "`date`"
git push origin master
