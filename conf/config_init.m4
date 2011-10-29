m4_divert(-1)
m4_changequote(`«', `»')
m4_define( «DEFINE»,
	   «m4_ifelse( «$#», 2,
	   	       «m4_define(««$»$1», «$2»)»,
		       «m4_errprint(m4___program__:m4___file__:m4___line__:«$0: 2 arguments required, got $#»)
		        m4_m4exit(1))»)»)
m4_define( «M4_DEFN»,
	   «m4_defn(««$»$1»)»)
