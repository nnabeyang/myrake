mytest: myrake.rb
	ruby -I/home/noriaki/dev/rake -I/home/noriaki/dev/rake/mytests -I/home/noriaki/dev/rake/rake runner.rb mytests
test: rake.rb
	ruby -I. -I./tests runner.rb tests

