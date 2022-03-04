#
# Print the CFG from the query in ./PrintCFG.ql
# 

#* Add codeql binary PATH
export PATH=$HOME/local/codeql-2.7.6/codeql:"$PATH"

#* Graph in dgml format 
cd ~/local/codeql-sample-polkit/
codeql database analyze                                 \
       ./db/polkit-0.119.db                             \
       ./PrintCFG.ql                                    \
       --rerun                                          \
       -j8 -v --ram=16000                               \
       --search-path $HOME/local/codeql-2.7.6/ql        \
       --format=dgml                                    \
       --output=PrintCFG.dgml

# Clean up the dgml (xml) output
tidy -xml PrintCFG.dgml/cpp/example/polkit/cfg.dgml | sponge PrintCFG.dgml/cpp/example/polkit/cfg.dgml

# Convert dgml to dot
./dgml2dot < PrintCFG.dgml/cpp/example/polkit/cfg.dgml > cfg.dot

# Produce the DAG we really want
dot -Tpdf < cfg.dot > cfg.pdf
open cfg.pdf

# Faster than dot, as sanity check:
sfdp -Tpdf < cfg.dot > cfg.sfdp.pdf
open cfg.sfdp.pdf

#* Full dot graph from codeql
# 
# The dot output from this was broken on [Mar- 3-2022]; use the above.
# 

# cd ~/local/codeql-sample-polkit/
# codeql database analyze                                 \
#        ./db/polkit-0.119.db                             \
#        ./PrintCFG.ql                                    \
#        -j8 -v --ram=16000                               \
#        --search-path $HOME/local/codeql-2.7.6/ql        \
#        --format=dot                                     \
#        --output=PrintCFG.dot

# # Query-produced .bqrs file
# ls db/polkit-0.119.db/results/cpp-polkit-argv/PrintCFG.bqrs 

# # Query-produced .dot file
# ls PrintCFG.dot/cpp/example/polkit/cfg.dot 

# # Generate SVG
# cd ~/local/codeql-sample-polkit/PrintIR-pkexec.dot/cpp/example/
# dot -Tsvg ./polkit-ir.dot > polkit-ir.svg

