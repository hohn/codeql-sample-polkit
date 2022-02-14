/**
 * @name Argv index out-of-bounds
 * @kind problem
 * @id cpp/example/argv-out-of-bounds
 */

import cpp

from Parameter argc 
where argc.getName() = "argc"
select argc, "Definition of argc"
