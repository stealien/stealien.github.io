git checkout master
rm -rf _site/
bundle exec jekyll build
mv _site docs
git add --all
git commit -m "`date`"
git push origin master
git subtree push --prefix=_site/ origin master
