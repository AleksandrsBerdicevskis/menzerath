PATH = "C:\\Sasha\\D\\DGU\\UD\\UD28Langs2#{addendum}" #change the path to the one you need. Make sure that subfolders data_means and detailed12 are present in the folder

@threshold = 50 #units with less than #{threshold} datapoints will be excluded
require 'unicode_utils\downcase' #simple downcase does not work properly for some scripts
require "rinruby" #to run statistical analysis in R

R.eval("library(\"effsize\")") #to calculate effect size

@clause_rels = ["csubj","ccomp","advcl","acl","parataxis"]

main_subtypes = ["csubj", "advcl", "xcomp", "ccomp"] #subtypes of the main clause (depending on which subordinate clause it has)
corr_rels = ["nsubj", "advmod", "obj"] #corresponing non-clausal relations
corr_types = {"csubj" => "nsubj", "advcl" => "advmod", "comp" => "obj"} #" xcomp" => "obj", "ccomp" => "obj"}

addendum = "" #for experiments. Can be ignored

#token_type = Hash.new("F")
#["ADJ", "ADV", "NOUN", "INTJ", "PROPN", "VERB", "NUM", "PRON"].each do |pos|
#    token_type[pos] = "C"
#end

#for curve analysis: compare two points and label the curve as "up", "down" or "flat"
def curve_shape(p,d)
    if p < 0.05 and d.abs > 0.20
        if d > 0
            curve = "down"
        else
            curve = "up"
        end
    else
        curve = "flat"
    end
    curve 
end

#for curve analysis: find how many points there are to compare (2, 3 or 4), compare the neighbouring ones (apply the Bonferroni correction), label the curve
def pattern_classification(word_by_clause,trendfile,language, level)
    #STDERR.puts level
    word_by_clause_t = {}
    word_by_clause.each_pair do |key, array|
        if array.length >= @threshold
            word_by_clause_t[key] = array
        end
    end
    #flag = true
    if word_by_clause_t.keys.length > 1
        word_by_clause3 = word_by_clause_t.sort_by{ |k, v| stats(v,"array")[0] } #sort by @words per clause
        minimum = word_by_clause3[0][0] #first point, minimum
        maximum = word_by_clause3[-1][0] #last point, maximum
        
        first_length = word_by_clause_t.keys.min
        last_length = word_by_clause_t.keys.max
        allpoints = [minimum, maximum, first_length, last_length]
        
        #p12 = nil
        p23 = nil
        p34 = nil
        #d12 = nil
        d23 = nil
        d34 = nil

        if allpoints.uniq.length == 2
            R.assign "w1", word_by_clause[first_length]
            R.assign "w2", word_by_clause[last_length]
            p12 = R.pull "t.test(w1,w2)$p.value"
            d12 = R.pull "cohen.d(w1,w2)$estimate"
            
        elsif allpoints.uniq.length == 3
            if (minimum == first_length or minimum == last_length)
                extremum = maximum
            else
                extremum = minimum
            end
            R.assign "w1", word_by_clause[first_length]
            R.assign "w2", word_by_clause[extremum]
            p12 = R.pull "t.test(w1,w2)$p.value"
            d12 = R.pull "cohen.d(w1,w2)$estimate"
            #R.assign "w2", word_by_clause[extremum]
            R.assign "w3", word_by_clause[last_length]
            p23 = R.pull "t.test(w2,w3)$p.value"
            d23 = R.pull "cohen.d(w2,w3)$estimate"
            p12 = p12 * 2
            p23 = p23 * 2
            
        else 
            #STDERR.puts "Alarm! I don't know what to do with #{allpoints} points of interest!"
            #flag = false
            if (minimum < maximum)
                firstextremum = minimum
                secondextremum = maximum
            else
                firstextremum = maximum
                secondextremum = minimum
            end
            R.assign "w1", word_by_clause[first_length]
            R.assign "w2", word_by_clause[firstextremum]
            p12 = R.pull "t.test(w1,w2)$p.value"
            d12 = R.pull "cohen.d(w1,w2)$estimate"
            #R.assign "w2", word_by_clause[extremum]
            R.assign "w3", word_by_clause[secondextremum]
            p23 = R.pull "t.test(w2,w3)$p.value"
            d23 = R.pull "cohen.d(w2,w3)$estimate"
            R.assign "w4", word_by_clause[last_length]
            p34 = R.pull "t.test(w3,w4)$p.value"
            d34 = R.pull "cohen.d(w3,w4)$estimate"

            p12 = p12 * 3
            p23 = p23 * 3
            p34 = p34 * 3
        end
        
        curve = ""
        curve2 = ""
        curve << curve_shape(p12, d12)
        curve2 << curve_shape(p12, d12)
        if !p23.nil?
            curve << "-"
            curve << curve_shape(p23, d23)
            if curve.split("-")[1] != "flat"
                curve2 << "-"
                curve2 << curve_shape(p23, d23)
            end
            if !p34.nil?
                curve << "-"
                curve << curve_shape(p34, d34)
                if curve.split("-")[2] != "flat"
                    curve2 << "-"
                    curve2 << curve_shape(p34, d34)
                end
            end
        end
        curve2.gsub!("flat-", "")
        
    end    
    trendfile.puts "#{language}\t#{p12}\t#{d12}\t#{p23}\t#{d23}\t#{p34}\t#{d34}\t#{first_length}\t#{minimum}\t#{maximum}\t#{last_length}\t#{curve}\t#{curve2}"
end 

#find average word length in an array. If asked to, add the number of words to a prespecified global variable
def ave_length(words, countwords) 
    total_length = 0.0
    words.each do |word|
        total_length += word.length
        if countwords
            @all_word_lengths_within_language_in_symbols << word.length
        end
    end
    ave_length = total_length/words.length
    ave_length
end

def median(array)
  return nil if array.empty?
  sorted = array.sort
  len = sorted.length
  (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
end

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

#go through the syntactic tree from the top...
def explore_tree(node,clauseroot)
    
    #...find all children of the current node
    children = @tree[node]
    
    if @poss[node] != "PUNCT" and !node.include?(".") #check if the node should be included
        mweflag = false #we have to check whether this token is part of an MWE
        if @mwe_node_to_range[node].nil?
            mweflag = true #no, it's not: no problems!
            clause_unit = @forms[node] #we'll just use the form as it is
        elsif @mwe_range_to_status[@mwe_node_to_range[node]] == 0 #it is. Let's check if we've already dealt with this MWE
            mweflag = true #we did!
            clause_unit = @mwe_node_to_realfrom[node] #we'll take the surface form as a word
            @mwe_range_to_status[@mwe_node_to_range[node]] = 1 #and we'll mark that we've already taken it
        #OTHERWISE: we just ignore the (non-surface) token
        end

        if mweflag #if we don't ignore the token
            @clause_lengths[clauseroot] += 1
            @clauses[clauseroot] << clause_unit
            @clauses_ids[clauseroot] << node
            @clause_type[clauseroot] = @rels[clauseroot]
        end
    end
    
    children.each do |child| #now we loop through the children
        if @clause_rels.include?(@rels[child]) or (@rels[child] == "conj" and (@poss[child] == "VERB" or @poss[node] == "VERB")) or (@rels[child] == "xcomp" and @poss[child] == "VERB")
            #STDERR.puts "clausal"
            explore_tree(child, child) #it's a beginning of a new clause, we run the function recursively with the node and mark that it's a clausehead
        else
            #STDERR.puts "nonclausal"
            explore_tree(child, clauseroot) #it's NOT a beginning of a new clause, we run the function recursively with the node and mark that it's NOT a clausehead
        end
    end
    
end

#to reproduce Macutek et al.'s analysis (with phrases as a sub-clause unit)
def fill_phrases
    phrases = {}
    @clauses_ids.each_pair do |clauseroot, nodes_in_clause|
        phrases[clauseroot] = Hash.new{|hash, key| hash[key] = Array.new}
        @tree[clauseroot].each do |underrootnode|
            if nodes_in_clause.include?(underrootnode)
                phrases[clauseroot][underrootnode] << @forms[underrootnode]
                #@alldescendants = []
                get_all_descendants(underrootnode, nodes_in_clause, phrases[clauseroot][underrootnode])
            end
        end
    end
    phrases
end

#to reproduce Macutek et al.'s analysis (with phrases as a sub-clause unit)
def get_all_descendants(node, nodes_in_clause, descendants)
    children = @tree[node]
    #STDERR.puts children.join(" ")
    if !children.empty?
        children.each do |childnode|
            if nodes_in_clause.include?(childnode)
                descendants << @forms[childnode]
                #STDERR.puts node
                #STDERR.puts descendants.join(" ")
                get_all_descendants(childnode, nodes_in_clause, descendants)
            end
        end
    end
end

filelist = Dir.entries(PATH).reject{|a| a[0]=="."}

#general length stats
o4 = File.open("#{addendum}mean_lengths.tsv","w:utf-8")
o4.puts "language\tsentence_in_clauses\tclause_in_words\twords_in_symbols\tsentence_in_words"

#clause-word-grapheme
o_clause_stats = File.open("#{addendum}clause_curves#{@threshold}.tsv","w:utf-8")
o_clause_stats.puts "language\tp12\td12\tp23\td23\tp34\td34\tstart\tminimum\tmaximum\tfinish\tcurve\tcurve2"

#sentence-word-grapheme
o_sentwords_stats = File.open("#{addendum}sentwords_curves#{@threshold}.tsv","w:utf-8")
o_sentwords_stats.puts "language\tp12\td12\tp23\td23\tp34\td34\tstart\tminimum\tmaximum\tfinish\tcurve\tcurve2"

sentidcounter = 0

type_across_langs = Hash.new{|hash, key| hash[key] = Array.new}
diff_across_langs = Hash.new{|hash, key| hash[key] = Array.new}
maintype_across_langs = Hash.new{|hash, key| hash[key] = Array.new}
corrtype_across_langs = Hash.new{|hash, key| hash[key] = Array.new}

filelist.each do |filename|
    STDERR.puts filename
    file = File.open("#{PATH}\\#{filename}","r:utf-8")
    
    #sentence-clause-word
    o1a = File.open("#{addendum}data_means\\#{filename.split(".")[0]}_sent.tsv","w:utf-8")
    o1a.puts "u1\tu2\tnobservations\tiqr"
    #clause-word-grapheme
    o2a = File.open("#{addendum}data_means\\#{filename.split(".")[0]}_clause.tsv","w:utf-8")
    o2a.puts "u1\tu2\tnobservations\tiqr"
    #sentence-word-grapheme
    o3a = File.open("#{addendum}data_means\\#{filename.split(".")[0]}_sentwords.tsv","w:utf-8")
    o3a.puts "u1\tu2\tnobservations\tiqr"

###comment out to speed up
    o5a = File.open("#{addendum}data_means\\#{filename.split(".")[0]}_sentclausephrase.tsv","w:utf-8")
    o5a.puts "u1\tu2\tnobservations\tiqr"
    o6a = File.open("#{addendum}data_means\\#{filename.split(".")[0]}_clausephraseword.tsv","w:utf-8")
    o6a.puts "u1\tu2\tnobservations\tiqr"
    o7a = File.open("#{addendum}data_means\\#{filename.split(".")[0]}_phrasewordgrapheme.tsv","w:utf-8")
    o7a.puts "u1\tu2\tnobservations\tiqr"
    
    #for the detailed analysis of the lengths of different subordinate (and main) clauses
    od = File.open("#{addendum}detailed12\\#{filename.split(".")[0]}.tsv","w:utf-8")
    od.puts "clause_type\tave_clause_in_words\tnobservations\tiqr"
    od2 = File.open("#{addendum}detailed12\\#{filename.split(".")[0]}_main.tsv","w:utf-8")
    od2.puts "clause_type\tave_clause_in_words\tnobservations\tiqr\tcorr_type_length\tncorrobservations\tdiff"

    token_freqs = Hash.new(0)
    file.each_line do |line|
        line1 = line.strip
        if line1 != "" 
            if line1[0] != "#"
                line2 = line1.split("\t")
                token = UnicodeUtils.downcase(line2[1]).gsub("\"","")
                token_freqs[token] += 1
            end
        end
    end
    file.close
    file = File.open("#{PATH}\\#{filename}","r:utf-8")

    main_subtype_lengths = Hash.new(0.0) #Hash.new{|hash, key| hash[key] = Array.new}
    main_subtype_ns = Hash.new(0.0)
    clause_length_per_type = Hash.new{|hash, key| hash[key] = Array.new}
    mainclause_length_per_type = Hash.new{|hash, key| hash[key] = Array.new}
    diff_per_type = Hash.new{|hash, key| hash[key] = Array.new}
    all_sentence_lengths_within_language_in_clauses = []
    clause_by_sentence = Hash.new{|hash, key| hash[key] = Array.new}
    phraseclause_by_sentence = Hash.new{|hash, key| hash[key] = Array.new}
    word_by_sentence = Hash.new{|hash, key| hash[key] = Array.new}
    word_by_clause = Hash.new{|hash, key| hash[key] = Array.new}
    word_by_phrase = Hash.new{|hash, key| hash[key] = Array.new}
    phrase_by_clause = Hash.new{|hash, key| hash[key] = Array.new}
    all_sentence_lengths_within_language_in_words = []
    all_clause_lengths_within_language_in_words = []
    @all_word_lengths_within_language_in_symbols = []
    @sentence_length_in_clauses = 1
    @clause_lengths = Hash.new(0)
    @clause_type = {}
    @main_clause_type = {}
    @tree = Hash.new{|hash, key| hash[key] = Array.new}
    @clauses = Hash.new{|hash, key| hash[key] = Array.new}
    @clauses_ids = Hash.new{|hash, key| hash[key] = Array.new}
    @poss = {}
    @rels = {}
    @forms = {}
    @mwe_node_to_realfrom = {}
    @mwe_node_to_range = {}
    @mwe_range_to_status = Hash.new(0)
    @mwe_range_to_realform = {}
    root = ""
    sent_id = ""
    file.each_line do |line|
        line1 = line.strip
        #STDERR.puts line
        if line1 != "" 
            if line1[0] != "#"
                line2 = line1.split("\t")
                
                form = line2[1]  #.gsub("\"","")
                id = line2[0]
                head = line2[6]
                pos = line2[3]
                rel = line2[7].split(":")[0]
                if !id.include?("-") #if not an MWE
                    if pos != "PUNCT"
                        if rel == "root"
                            root = id
                        end
                        @tree[head] << id
                        @poss[id] = pos
                        @forms[id] = form
                        @rels[id] = rel
                    end
                else #recording all info about MWEs so that we can deal with them correctly in explore_tree
                    mwerange = (id.split("-")[0]..id.split("-")[1]).to_a
                    @mwe_range_to_realform[id] = form
                    mwerange.each do |mweunit|
                        @mwe_node_to_realfrom[mweunit] = form
                        @mwe_node_to_range[mweunit] = id
                        
                    end
                    
                end
                 
                #end
            elsif line1[0..8] == "# sent_id"
                sent_id = line1.split(" = ")[1]
                if sent_id.to_s == ""
                    sent_id = "artificial_sent_id_#{sentidcounter}"
                    sentidcounter += 1
                end
                #STDERR.puts sent_id
            end
        else
            #The sentence has ended. We will update the stats now
            if !@poss.values.include?("SYM") and !@poss.values.include?("X")
                if root != ""
                    sentence_length_in_words = @forms.keys.length + @mwe_range_to_realform.keys.length
                    all_sentence_lengths_within_language_in_words << sentence_length_in_words
                    words_in_sentence = @forms.values + @mwe_range_to_realform.values
                    if !words_in_sentence.empty?
                        ave_length_words_in_sentence = ave_length(words_in_sentence, true)
                        #o3.puts "#{sent_id}\t#{sentence_length_in_words}\t#{ave_length_words_in_sentence}"        
                        word_by_sentence[sentence_length_in_words] << ave_length_words_in_sentence
                        explore_tree(root,root)
                    end
                end
                if !@clause_lengths.values.include?(0) and !@clause_lengths.values.empty?
                    #STDERR.puts "#{@clause_lengths}"
                    @sentence_length_in_clauses = @clause_lengths.keys.length
                    
                    all_sentence_lengths_within_language_in_clauses << @sentence_length_in_clauses
                    ave_length_clause_in_sentence = stats(@clause_lengths, "hash")[0]
                    #o.puts "#{sent_id}\t#{@sentence_length_in_clauses}\t#{ave_length_clause_in_sentence}"
                    phrases = fill_phrases ###comment out to speed up
                    clause_by_sentence[@sentence_length_in_clauses] << ave_length_clause_in_sentence
                    total_clause_length_in_phrases = 0.0 ###comment out to speed up

                    main_clause_length = 0
                    #dep_clause_length = 0
                    main_clause_type = ""
                    @clauses.each_pair do |clauseroot, words_in_clause|
                        #STDERR.puts clauseroot
                        #STDERR.puts words_in_clause.join(" ")
                        all_clause_lengths_within_language_in_words << @clause_lengths[clauseroot]
                        clause_length_in_words = words_in_clause.length
                        ave_length_words_in_clause = ave_length(words_in_clause, false)
                        #o2.puts "#{sent_id}___#{clauseroot}\t#{clause_length_in_words}\t#{ave_length_words_in_clause}"
                        word_by_clause[clause_length_in_words] << ave_length_words_in_clause
                        clause_length_in_phrases = phrases[clauseroot].keys.length ###comment out to speed up
                        total_clause_length_in_phrases += clause_length_in_phrases ###comment out to speed up
                        total_phrase_length_in_words = 0.0 ###comment out to speed up
                        phrases[clauseroot].each_value do |words_in_phrase| ###comment out to speed up
                            total_phrase_length_in_words += words_in_phrase.length ###comment out to speed up
                            word_by_phrase[words_in_phrase.length] << ave_length(words_in_phrase, false) ###comment out to speed up
                        end ###comment out to speed up
                        ave_phrase_length_in_words = total_phrase_length_in_words / clause_length_in_phrases ###comment out to speed up
                        if clause_length_in_phrases != 0 ###comment out to speed up
                            phrase_by_clause[clause_length_in_phrases] << ave_phrase_length_in_words ###comment out to speed up
                        end ###comment out to speed up

                        #STDERR.puts "tree: #{@tree}"
                        if @sentence_length_in_clauses == 1
                            clause_length_per_type["simple"] << clause_length_in_words
                            #STDERR.puts "1 clause!"
                            @clauses_ids[clauseroot].each do |id|
                                #STDERR.puts id
                                #STDERR.puts @rels[id]
                                if corr_rels.include?(@rels[id])
                                    #STDERR.puts "Relevant rel"
                                    descendants = [id]
                                    get_all_descendants(id, @clauses_ids[clauseroot], descendants)
                                    #STDERR.puts "result: #{descendants}"
                                    main_subtype_lengths[@rels[id]] += descendants.length
                                    main_subtype_ns[@rels[id]] += 1
                                end
                            end
                        elsif @sentence_length_in_clauses == 2
                            
                            if @clause_type[clauseroot] == "root"
                                main_clause_length = clause_length_in_words
                                clause_length_per_type["main"] << clause_length_in_words
                            else
                                main_clause_type << "#{@clause_type[clauseroot]}"
                                clause_length_per_type[@clause_type[clauseroot]] << clause_length_in_words
                                #main_clause_length = clause_length_in_words
                            end
                        end
                    end
                    if main_clause_type != ""
                        mainclause_length_per_type[main_clause_type] << main_clause_length
                    end

                    
                    ave_clause_length_in_phrases = total_clause_length_in_phrases / @sentence_length_in_clauses ###comment out to speed up
                    phraseclause_by_sentence[@sentence_length_in_clauses] <<  ave_clause_length_in_phrases ###comment out to speed up
                    
                end
            end
            @sentence_length_in_clauses = 1
            @clause_lengths = Hash.new(0)
            @clauses = Hash.new{|hash, key| hash[key] = Array.new}
            @tree = Hash.new{|hash, key| hash[key] = Array.new}
            @mwe_node_to_realfrom = {}
            @mwe_node_to_range = {}
            @mwe_range_to_status = Hash.new(0)
            @mwe_range_to_realform = {}
            @poss = {}
            @rels = {}
            @forms = {}
            root = ""
        end
    end

    #OUTPUT
    o4.puts "#{filename.split(".")[0]}\t#{stats(all_sentence_lengths_within_language_in_clauses, "array")[0]}\t#{stats(all_clause_lengths_within_language_in_words, "array")[0]}\t#{stats(@all_word_lengths_within_language_in_symbols, "array")[0]}\t#{stats(all_sentence_lengths_within_language_in_words, "array")[0]}"    
    
    pattern_classification(word_by_sentence,o_sentwords_stats,filename.split(".")[0],"sentwords")
    word_by_sentence2 = word_by_sentence.sort_by{ |k, v| k }
    word_by_sentence2.each do |pair|
        R.assign "lengths", pair[1]
        iqr = R.pull "IQR(lengths)"
        o3a.puts "#{pair[0]}\t#{stats(pair[1],"array")[0]}\t#{pair[1].length}\t#{iqr}"
        
    end
    
    
    pattern_classification(word_by_clause,o_clause_stats,filename.split(".")[0],"clause")
    word_by_clause2 = word_by_clause.sort_by{ |k, v| k } 
    word_by_clause2.each do |pair|
    
        R.assign "lengths", pair[1]
        iqr = R.pull "IQR(lengths)"
        o2a.puts "#{pair[0]}\t#{stats(pair[1],"array")[0]}\t#{pair[1].length}\t#{iqr}"
        
    end

###comment out to speed up
    word_by_phrase2 = word_by_phrase.sort_by{ |k, v| k }  
    word_by_phrase2.each do |pair|
    
        R.assign "lengths", pair[1]
        iqr = R.pull "IQR(lengths)"
        o7a.puts "#{pair[0]}\t#{stats(pair[1],"array")[0]}\t#{pair[1].length}\t#{iqr}"
        
    end

    clause_by_sentence2 = clause_by_sentence.sort_by{ |k, v| k } 
    clause_by_sentence2.each do |pair|
        R.assign "lengths", pair[1]
        iqr = R.pull "IQR(lengths)"
        o1a.puts "#{pair[0]}\t#{stats(pair[1],"array")[0]}\t#{pair[1].length}\t#{iqr}"
        
    end

###comment out to speed up
    phraseclause_by_sentence2 = phraseclause_by_sentence.sort_by{ |k, v| k } 
    phraseclause_by_sentence2.each do |pair|
        
        R.assign "lengths", pair[1]
        iqr = R.pull "IQR(lengths)"
        o5a.puts "#{pair[0]}\t#{stats(pair[1],"array")[0]}\t#{pair[1].length}\t#{iqr}"
        
    end

###comment out to speed up
    phrase_by_clause2 = phrase_by_clause.sort_by{ |k, v| k } 
    phrase_by_clause2.each do |pair|
        
        R.assign "lengths", pair[1]
        iqr = R.pull "IQR(lengths)"
        o6a.puts "#{pair[0]}\t#{stats(pair[1],"array")[0]}\t#{pair[1].length}\t#{iqr}"
        
    end

    mainclause_length_per_type["comp"] = [mainclause_length_per_type["ccomp"], mainclause_length_per_type["xcomp"]].flatten
    main_subtype_lengths.each_pair do |type, value|
        main_subtype_lengths[type] = value/main_subtype_ns[type]
    end

    mainclause_length_per_type.each do |type, lengtharray|
        R.assign "lengths", lengtharray
        iqr = R.pull "IQR(lengths)"
        if !corr_types[type].nil?
            #corrlengtharray = main_subtype_lengths[corr_types[type]]
            #R.assign "lengths2", corrlengtharray
            #iqr2 = R.pull "IQR(lengths2)"
            main_clause_length = stats(lengtharray,"array")[0]
            corr_nonclausal_length = main_subtype_lengths[corr_types[type]] #stats(corrlengtharray,"array")[0]
            simple_clause_length = stats(clause_length_per_type["simple"],"array")[0]
            diff = simple_clause_length - (main_clause_length + corr_nonclausal_length)
            diff_per_type[type] = diff
            od2.puts "#{type}\t#{main_clause_length}\t#{lengtharray.length}\t#{iqr}\t#{corr_nonclausal_length}\t#{main_subtype_ns[corr_types[type]]}\t#{diff}"
        else
            od2.puts "#{type}\t#{stats(lengtharray,"array")[0]}\t#{lengtharray.length}\t#{iqr}"
        end

        
        #od2.puts "clause_type\tave_clause_in_words\tnobservations\tiqr\tcorr_type_length\tncorrobservations\tcorriqr"
    end

    clause_length_per_type2 = clause_length_per_type.sort_by{ |k, v| stats(v,"array")[0]}.reverse
    clause_length_per_type2.each do |pair|
        R.assign "lengths", pair[1]
        iqr = R.pull "IQR(lengths)"
        
        od.puts "#{pair[0]}\t#{stats(pair[1],"array")[0]}\t#{pair[1].length}\t#{iqr}"
    end
    
    file.close
    #o.close
    refpoint = stats(clause_length_per_type["simple"],"array")[0] 
    clause_length_per_type.each_pair do |type, array|
        type_across_langs[type] << stats(array,"array")[0]/refpoint #normalized mean within language becomes an element in a cross-linguistic array
    end
    
    #main_refpoint = stats(clause_length_per_type["simple"],"array")[0] 
    mainclause_length_per_type.each_pair do |type, array|
        maintype_across_langs[type] << stats(array,"array")[0]/refpoint #normalized mean within language becomes an element in a cross-linguistic array
        if !corr_types[type].nil?
            #corrtype_across_langs[type] << stats(main_subtype_lengths[corr_types[type]],"array")[0]/refpoint
            corrtype_across_langs[type] << main_subtype_lengths[corr_types[type]]/refpoint
            diff_across_langs[type] << diff_per_type[type]/refpoint
        end
    end
    
end #filelist end 


