$last_dir = Dir.pwd
$test_dir = 'mytests'
def notify(fn)
  result = `make 2>&1`
  dir = $last_dir
  $last_dir = Dir.pwd
  Dir.chdir(dir)
  /(\d+ tests, \d+ assertions, \d+ failures, \d+ errors, \d+ skips)/ =~ result
  system("notify-send #{fn} \"#{$1}\"")
  if fn.match(/^#{$test_dir}/) || !File.exist?("#{Dir.pwd}/.#{fn}.swp")
   puts result
  end
  Dir.chdir($last_dir)
end

watch( 'myrake\.rb' )  {|md|
  notify(md[0])
}

watch( "#{$test_dir}/(.*\.rb)" )  {|md|
  system("touch myrake.rb")
}
