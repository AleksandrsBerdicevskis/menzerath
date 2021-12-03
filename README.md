# menzerath
 This repository contains the data and the scripts that are necessary to reproduce the results reported in: Berdicevskis, Aleksandrs. 2021. Successes and failures of Menzerath's law at the syntactic level

Install Ruby to run the .rb files, any reasonably recent version should work. Install the `rinruby` gem, make sure that R (with `effsize` package) is installed on your machine.

The repository contains the following files and folders 

- `ud_merge.rb`: a script that goes through all UD 2.8 folders and merges `train`, `dev` and `test` part of every treebank into a single file in the same folder. Set the correct PATH at the beginning of the script.

- `ud_merge_perlang.rb2`: a script that goes through all UD 2.8 treebanks and merges all treebanks for the same language into a single file. Set the IN and OUT paths at the beginning of the script. Treebanks that do not meet the predefined criteria (see Section 3 in the paper) are discarded. The list of all treebanks that are included in the sample is created in `included_ud28_languages.tsv`. The script assumes that `ud_merge.rb` has already been run and a single conllu file exists for every treebank.

- `menz_ud03.rb`: the main analysis script which goes through all treebanks. It assumes that `ud_merge_perlang2.rb` has been run and that its output has been placed where PATH variable at the very beginning leads (change PATH if necessary). The script is very slow, especially on large treebanks like German and Czech. It will work noticeably faster if phrase analysis (Section 6 in the paper) is turned off (find the comment line `###comment out to speed up`). The threshold (the minimum number of datapoints per unit is; units with smaller number of datapoints are excluded from the analysis) is specified at the beginning of the script. The script will output:
    - several files per language with language-specific results (mean length of a sub-unit per unit length; number of observations; IQR) in the `data_means` folder (the folder must exist), where:
        - `sent = sentence--clause--word (Section 4.1)
        - `clause = clause--word--grapheme (Section 5)
        - `sentwords` - sentence--word--grapheme (Section 6)
        - other labels are self-explanatory (Section 6)
    - two files per language in the `detailed12` folder (the folder must exist), where:
        - `main` = analysis of main clauses with various subordinate clauses (Section 4.2; Table 2)
        - no label = analysis of various subordinate clauses (Section 4.2; Table 2)
    - `mean_lengths.tsv`: basic statistics about every language (not reported in the paper)
    - `clause_curves#{threshold}.tsv`: labeling the curves (for clause--word--grapheme) according to their pattern (Section 5, Appendix B). The default threshold is 50
    - `sentwords_curves#{threshold}`: labeling the curves (for sentence--word--grapheme) according to their pattern (not reported in the paper). The default threshold is 50

- analyze_means.rb: this script uses the contents of the `data_means` folder to run a higher-level analysis. Specify the threshold and the level of analysis (`sent`, `clause`, etc., see the legend above; the label must match the labels in the `data_means` folder). The script outputs two files: 
    - `results_means_#{level}_#{threshold}.tsv`: results of Spearman correlation test for every language; range (the maximum value of the unit length) (Appendix A; Table 7)
    - `summary_means_#{level}_#{threshold}.tsv`: how many languages (absolute value and relative value) can be labelled as "Menzerathian", "anti-Menzerathian" or "undefined" (Table 1; Section 6)
    
- analyze_detailed.rb: this script uses the contents of the `data_means` folder to reproduce the analysis described in Section 4.2 and outputs two files (    `clause_types.tsv` and `main_clause_types.tsv`), cf. Table 2.

Output files provided by all the scripts are also included.
