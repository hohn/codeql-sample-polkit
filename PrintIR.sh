#
# Print the IR representation of a function
# 

# Add codeql binary PATH
export PATH=$HOME/local/codeql-2.7.6/codeql:"$PATH"

#* Plain text dump of graph
codeql database analyze                                 \
       ./db/polkit-0.119.db                             \
       ./PrintIR-pkexec.ql                              \
       -j8 -v --ram=16000                               \
       --search-path $HOME/local/codeql-2.7.6/ql        \
       --format=graphtext                               \
       --output=PrintIR-pkexec.graphtext

# .txt file
ls  PrintIR-pkexec.graphtext/cpp/example/polkit-ir.txt 

#* Full dot graph 
cd ~/local/codeql-sample-polkit/
codeql database analyze                                 \
       ./db/polkit-0.119.db                             \
       ./PrintIR-pkexec.ql                              \
       -j8 -v --ram=16000                               \
       --search-path $HOME/local/codeql-2.7.6/ql        \
       --format=dot                                     \
       --output=PrintIR-pkexec.dot

# Note: intermediate files are here:

# Query-produced .bqrs file
ls db/polkit-0.119.db/results/cpp-polkit-argv/

# Query-produced .dot file
ls PrintIR-pkexec.dot/cpp/example/polkit-ir.dot 

# Generate SVG
cd ~/local/codeql-sample-polkit/PrintIR-pkexec.dot/cpp/example/
dot -Tsvg ./polkit-ir.dot > polkit-ir.svg
# 
# XX: dot output issue: https://github.slack.com/archives/CPCFXL8P3/p1646270812905149
# 
open -a safari ./print-ast.svg
