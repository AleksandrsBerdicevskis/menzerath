@threshold = 50
level = "phrasewordgrapheme"

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
type = "means"
addendum = ""

directory = "#{addendum}data_#{type}"

filelist = Dir.entries(directory).reject{|a| a[0]=="."}
o2 = File.new("#{addendum}results_#{type}_#{level}_#{@threshold}.tsv","w:utf-8")
o2.puts "language\tr\tp\trange"
lengths_clause = {}

u1 = []
u2 = []
pro_menz = 0.0
contra_menz = 0.0
undecided = 0.0
total = 0.0

filelist.each do |filename|
    language = filename.split("_")[0..-2].join("_")
    #STDERR.puts filename
    #STDERR.puts language
    f = File.open("#{directory}\\#{filename}","r:utf-8")
    if filename.split("_")[-1] == "#{level}.tsv"
        #STDERR.puts language
        f.each_line.with_index do |line, index|
            line1 = line.strip
            if index > 0
                line2 = line1.split("\t")
                #STDERR.puts line2
                if line2[2].to_i >= @threshold
                    u1 << line2[0].to_f
                    u2 << line2[1].to_f
                end
            end
        end
    
        f.close
        #STDERR.puts u1.join(" ")
        #STDERR.puts ""
        #STDERR.puts u2.join(" ")
        #STDERR.puts ""
        
        R.assign "u1", u1
        R.assign "u2", u2
        p = R.pull "cor.test(u1,u2,method='spearman')$p.value"
        rho = R.pull "cor.test(u1,u2,method='spearman')$estimate"
        o2.puts "#{language}\t#{rho}\t#{p}\t#{u1.max}"
        u1 = []
        u2 = []
        if !rho.nil?
            total += 1
            if rho <= -0.7 
                pro_menz += 1
            elsif rho >= 0.7
                contra_menz += 1
            elsif p < 0.05
                if rho <= -0.3 
                    pro_menz += 1
                elsif rho >= 0.3
                    contra_menz += 1
                end
            else
                undecided += 1
                #STDERR.puts language
            end
        end
    end
end

o = File.new("#{addendum}summary_#{type}_#{level}_#{@threshold}.tsv","w:utf-8")
o.puts "pro_abs\tpro_rel\tcontra_abs\tcontra_rel\tundefined_abs\tundefined_rel"
o.puts "#{pro_menz}\t#{pro_menz/total}\t#{contra_menz}\t#{contra_menz/total}\t#{undecided}\t#{undecided/total}"