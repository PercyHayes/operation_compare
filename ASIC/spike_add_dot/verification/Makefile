#-------------------------------------------------------------------------------------------------------
all: \
		vcs \
		verdi

#-------------------------------------------------------------------------------------------------------
# VCS
vcs   :
	vcs  \
		-f file_list.f \
		-timescale=1ns/1ns \
		-full64  -R  +vc  +v2k  -sverilog  -debug_access+all  \
		|tee vcs.log  
#-------------------------------------------------------------------------------------------------------

# VCS_POST
vcs_post   :
	vcs  \
		-f post_list.f \
		-timescale=1ns/1ns \
		-full64  -R  +vc  +v2k  -sverilog  -debug_access+all  \
		|tee vcs.log  
#-------------------------------------------------------------------------------------------------------

# verdi

verdi  :
	verdi -sv -f file_list -ssf tb.fsdb &

#-------------------------------------------------------------------------------------------------------
clean  :
	 rm  -rf  *~  core  csrc  simv*  vc_hdrs.h  ucli.key  urg* *.log  novas.* *.fsdb* verdiLog  64* DVEfiles *.vpd
	 rm -rf INCA_libs irun*
	 rm -rf modelsim.ini transcript work
#-------------------------------------------------------------------------------------------------------
