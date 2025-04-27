.PHONY: sorbet
sorbet:
	bundle exec srb tc

rbi:
	bundle exec tapioca dsl

gem-rbis:
	bundle exec tapioca gems --no-doc --no-loc
