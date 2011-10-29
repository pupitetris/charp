m4_changecom(«--», «
»)
m4_divert«»m4_dnl
m4_undefine( m4_esyscmd(«echo m4_dumpdef | m4 -P 2>&1 | grep -v '^m4_defn:' | sed 's/^\([^:]\+\).*/«\1»,/g'»)
	     «CONF_USER»,
	     «CONF_DATABASE»,
	     «CONF_LOCALE»,
	     «CONF_SQLDIR»,
	     «DEFINE»)«»m4_dnl