filelist = Dir.entries("ud-treebanks-v2.8").reject{|a| a == "." or a == ".." or a[-3..-1]=="txt" or a[-3..-1]==".rb"}
filelist.each do |directory2|
  STDERR.puts directory2[3..-1]
  directory = "ud-treebanks-v2.8\\#{directory2}"
  conllu = Dir.entries(directory).reject{|a| a == "." or a == ".." or a[-6..-1]!="conllu"}
  txt = Dir.entries(directory).reject{|a| a == "." or a == ".." or a[-3..-1]!="txt" or !a.include?("-ud-")}
  of = File.new("#{directory}/#{directory2[3..-1]}.conllu","w:utf-8")
  conllu.each do |file|
    inf = File.open("#{directory}/#{file}","r:utf-8")
	inf.each_line do |line|
	  of.puts line	
	end  
	inf.close
  end
  of.close
  
  of = File.new("#{directory}/#{directory2[3..-1]}.txt","w:utf-8")
  txt.each do |file|
    inf = File.open("#{directory}/#{file}","r:utf-8")
	inf.each_line do |line|
	  of.puts line	
	end  
	inf.close
  end
  of.close
  
  #STDERR.puts conllu, txt
  #break
end