

vifm: link-vifm-plugin
	# MYVIFMRC=${PWD}/vifmrc vifm
	#
	# vifm \
	# 	+'filetype   * #nvim#open' \
	# 	+'fileviewer * #nvim#view' \
	# 	+'set vicmd=#nvim#vicmd'
	#
	vifm +'filetype * #nvim#open'


link-vifm-plugin:
	ln -sf ${PWD}/vifm ~/.config/vifm/plugins/nvim
