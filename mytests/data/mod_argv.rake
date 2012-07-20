task :default do|t|
  ARGV << "t1" << "t2"
  puts t.name
end
task :t1 do|t| puts t.name end
task :t2 do|t| puts t.name end
