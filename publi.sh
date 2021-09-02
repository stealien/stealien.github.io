git checkout site
rm -rf _site/
bundle exec jekyll build
git add --all
git commit -m "`date`"
git push origin site
git subtree push --prefix=_site/ origin master
