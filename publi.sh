git checkout master
rm -rf _site/
bundle exec jekyll build
git add --all
git commit -m "`date`"
git push origin master --allowed-unrelated-histories
git subtree push --prefix=_site/ origin master
