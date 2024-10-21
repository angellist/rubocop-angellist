.PHONY: sorbet
sorbet:
	bundle exec srb tc

rbi:
	bundle exec tapioca dsl

rbi_gems:
	bundle exec tapioca gems
