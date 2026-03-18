Recreation of TCL based project:
1. Open Vivado 20xx.x 
   Vivado version can be checked by opening <project>/project.tcl with text editor
   On line 2 there should be something like "# Vivado (TM) v2022.2 (64-bit)"
2. In Vivado: klick "Tools" -> "Run Tcl Script" -> open <project>/project.tcl
   Executing the project.tcl script recreates the Vivado and Vitis project. 
   The recreating takes some time, depending on the complexity of the project.
3. Vivado Project can be build by clicking "Generate Bitstream"
4. Open Vitis 20xx.x
5. Select Workspace <project>/vitis and click "Launch"
6. In Vitis close "Welcome" screen to enter the design view