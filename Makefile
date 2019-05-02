readme:
	cpanm -l dzil-local -n Pod::Markdown
	perl -I dzil-local/lib/perl5/ dzil-local/bin/pod2markdown lib/MooseX/App.pm > README.md
