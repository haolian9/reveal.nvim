

vifm: link-vifm-plugin
	vifm +'filetype * #nvim#open'


link-vifm-plugin:
	ln -sf ${PWD}/vifm ~/.config/vifm/plugins/nvim
