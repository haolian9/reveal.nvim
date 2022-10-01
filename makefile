

vifm: link-vifm-plugin
	# MYVIFMRC=${PWD}/vifmrc vifm
	vifm \
		+'filetype   * #nvim#open' \
		+'fileviewer * #nvim#view' \
		+'set vicmd=#nvim#vicmd'


link-vifm-plugin:
	ln -sf ${PWD}/vifm ~/.config/vifm/plugins/nvim
