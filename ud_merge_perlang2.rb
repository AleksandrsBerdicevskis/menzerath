#excluding languages where there are no forms and where there are less than #{threshold} tokens
#FIX: why does not Hindi English disappear? Naija and Coptic do not get copied: problems with escaping?

INPATH = "C:\\Sasha\\D\\DGU\\UD\\ud-treebanks-v2.8"
OUTPATH = "C:\\Sasha\\D\\DGU\\UD\\UD28langs2"

filelist = Dir.entries(INPATH).reject{|a| a == "." or a == ".." or a[-3..-1]=="txt" or a[-3..-1]==".rb"}
languagefiles = {}
languagesizes = Hash.new(0)
threshold = 10000
filelist.each do |directory|
    language = directory[3..-1].split("-")[0]
    STDERR.puts language
    STDERR.puts directory[3..-1]
    #conllu = Dir.entries(directory).reject{|a| a == "." or a == ".." or a[-6..-1]!="conllu"}
    
 
    includes_text = false
    mr_flag = false
    filelist = Dir.entries("#{INPATH}\\#{directory}")
    #STDERR.puts filelist
    if filelist.include?("README.txt")
        readmefile = "README.txt"
    elsif filelist.include?("README.md")
        readmefile = "README.md"
    end

    readme = File.open("#{INPATH}\\#{directory}\\#{readmefile}","r:utf-8")
    readme.each_line do |line|
        line1 = line.strip
        if line1.include?("Machine-readable metadata") or line1.include?("Machine readable metadata")
            mr_flag = true
        end
        if mr_flag and line1.include?("Includes text")
            if line1.split(":")[1].strip == "yes"
                includes_text = true
            end
            break
        end
    end

    if includes_text
        if languagefiles[language].nil?
            languagefiles[language] = File.new("#{OUTPATH}\\#{language}.conllu","w:utf-8")
        end
        conllufile = File.open("#{INPATH}\\#{directory}\\#{directory[3..-1]}.conllu","r:utf-8")
        #conllu.each do |file|
        #  inf = File.open("#{directory}/#{file}","r:utf-8")
        conllufile.each_line do |line|
            languagefiles[language].puts line
            line1 = line.strip
            if line1 != "" and line1[0] != "#" 
                if !line1.split("\t")[0].include?("-") and !line1.split("\t")[0].include?(".")
                    languagesizes[language] += 1
                end
            end
        end  
        conllufile.close
    else
        STDERR.puts "No text"
    end
end

lang2list = File.open("included_ud28_languages.tsv", "w:utf-8")
#deleted = File.open("excluded_ud28_languages.tsv", "w:utf-8")
languagesizes.each_pair do |language, size|
    if size < threshold
        #deleted.puts "#{language}\t#{size}"
        languagefiles[language].close
        File.delete(languagefiles[language])
    elsif language == "Naija"
        #deleted.puts "#{language}\ttoo many DEPs"
        languagefiles[language].close
        File.delete(languagefiles[language])
    else
        lang2list.puts "#{language}\t#{size}"
    end
end