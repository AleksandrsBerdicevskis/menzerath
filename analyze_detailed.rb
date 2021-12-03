

def stats(input, type)
    if type == "hash"
        sent_array = input.values
    elsif type == "array"
        sent_array = input
    end
    sent_sum = 0.0
    sent_array.each do |sent|
        sent_sum += sent
    end
    mean = sent_sum/sent_array.length
    
    sumsq = 0.0
    sent_array.each do |sent|
        sumsq += (mean - sent)*(mean - sent)
    end
    sd = Math.sqrt(sumsq/sent_array.length)
    return mean, sd
end

require "rinruby"
#type = "means"

directory = "detailed12"
filelist = Dir.entries(directory).reject{|a| a[0]=="."}
o2 = File.new("clause_types.tsv","w:utf-8")
o2.puts "type	rel_length	iqr	nobservations"
o3 = File.new("main_clause_types.tsv","w:utf-8")
o3.puts "type	rel_length	iqr	nobservations	corr_length	corriqr	nobservationscorr	diff	diffiqr"

type_across_langs = Hash.new{|hash, key| hash[key] = Array.new}
diff_across_langs = Hash.new{|hash, key| hash[key] = Array.new}
maintype_across_langs = Hash.new{|hash, key| hash[key] = Array.new}
corrtype_across_langs = Hash.new{|hash, key| hash[key] = Array.new}
difftype_across_langs = Hash.new{|hash, key| hash[key] = Array.new}
refpoint = 0.0
@threshold = 50

filelist.each do |filename|
    language = filename.split("_")[0..-2].join("_")
    #STDERR.puts filename
    STDERR.puts language
    f1 = File.open("#{directory}\\#{filename}","r:utf-8")
    
    
    if filename.split("_")[-1] != "main.tsv"
        type_within_lang = {}
        #STDERR.puts language
        f1.each_line.with_index do |line, index|
            line1 = line.strip
            if index > 0
                line2 = line1.split("\t")
                if line2[2].to_i >= @threshold
                    type_within_lang[line2[0]] = line2[1].to_f
                end
            end
        end
        f1.close
        refpoint = type_within_lang["simple"]
        type_within_lang.each_pair do |type, length|
            type_across_langs[type] << length/refpoint
        end
    else
        #STDERR.puts "here!"
        maintype_within_lang = {}
        corrtype_within_lang = {}
        difftype_within_lang = {}

        f1.each_line.with_index do |line, index|
            line1 = line.strip
            if index > 0
                line2 = line1.split("\t")
                if line2[2].to_i >= @threshold
                    maintype_within_lang[line2[0]] = line2[1].to_f
                    #STDERR.puts line2.length
                    if line2.length > 4
                        
                        corrtype_within_lang[line2[0]] = line2[4].to_f
                        difftype_within_lang[line2[0]] = line2[6].to_f
                    end
                end
            end
        end
        f1.close
        maintype_within_lang.each_pair do |type, length|
            maintype_across_langs[type] << length/refpoint
            if !corrtype_within_lang[type].nil?
                corrtype_across_langs[type] << corrtype_within_lang[type]/refpoint
                difftype_across_langs[type] << difftype_within_lang[type]/refpoint
            end
        end
    end
end

type_across_langs.each_pair do |type, lengtharray|
    R.assign "lengths", lengtharray
    iqr = R.pull "IQR(lengths)"
    o2.puts "#{type}\t#{stats(lengtharray,"array")[0]}\t#{iqr}\t#{lengtharray.length}"
end

maintype_across_langs.each_pair do |type, lengtharray|
    R.assign "lengths", lengtharray
    iqr = R.pull "IQR(lengths)"
    if corrtype_across_langs[type].empty?
        o3.puts "#{type}\t#{stats(lengtharray,"array")[0]}\t#{iqr}\t#{lengtharray.length}"
    else
        R.assign "lengths", corrtype_across_langs[type]
        iqr2 = R.pull "IQR(lengths)"
        R.assign "lengths", difftype_across_langs[type]
        iqr3 = R.pull "IQR(lengths)"
    
        o3.puts "#{type}\t#{stats(lengtharray,"array")[0]}\t#{iqr}\t#{lengtharray.length}\t#{stats(corrtype_across_langs[type], "array")[0]}\t#{iqr2}\t#{corrtype_across_langs[type].length}\t#{stats(difftype_across_langs[type], "array")[0]}\t#{iqr3}"
    end
end



#o3.puts "type	rel_length	iqr	nobservations	corr_length	corriqr	nobservationscorr	diff	diffiqr"