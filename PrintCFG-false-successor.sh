#
# Print a two-colored graph by using two queries' output;  one with all nodes for
# layout, the other with false-successor nodes for coloring.
# 

#* Add codeql binary PATH
export PATH=$HOME/local/codeql-2.7.6/codeql:"$PATH"

#* Graph in dgml format 
cd ~/local/codeql-sample-polkit/
codeql database analyze                                 \
       ./db/polkit-0.119.db                             \
       ./PrintCFG-false-successor.ql                    \
       --rerun                                          \
       -j8 -v --ram=16000                               \
       --search-path $HOME/local/codeql-2.7.6/ql        \
       --format=dgml                                    \
       --output=PrintCFG.dgml

# Clean up the dgml (xml) output
OUT=PrintCFG.dgml/cpp/example/polkit/cfg-false-successor.dgml
tidy -xml $OUT | sponge $OUT

# Compare node Ids.  They overlap, so graph visuals should work.
em PrintCFG.dgml/cpp/example/polkit/cfg-false-successor.dgml
em PrintCFG.dgml/cpp/example/polkit/cfg.dgml

# Produce a full graph with false-successor nodes colored
./dgml2dot -m PrintCFG.dgml/cpp/example/polkit/cfg-false-successor.dgml < \
           PrintCFG.dgml/cpp/example/polkit/cfg.dgml > \
           PrintCFG.dgml/cpp/example/polkit/cfg-false-successor-colored.dot

# Produce the DAG we really want
CFG=PrintCFG.dgml/cpp/example/polkit/cfg-false-successor-colored
dot -Tpdf < $CFG.dot > $CFG.pdf &
open $CFG.pdf

