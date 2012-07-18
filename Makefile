PWD = `pwd`
mytest: myrake.rb
	ruby -I${PWD} runner.rb mytests

