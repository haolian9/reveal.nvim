

vifm: link-vifm-plugin
	vifm +'filetype * #nvim#open'

VIFM := ${HOME}/.config/vifm/plugins
link-vifm-plugin:
	mkdir -p ${VIFM}
	if [ -L "${VIFM}/nvim" ]; then :; else ln -s "${PWD}/vifm" "${VIFM}/nvim"; fi
