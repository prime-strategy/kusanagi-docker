#!

xgettext --package-name=kusanagi-docker \
		--package-version=1.0 \
		-L shell \
		--no-wrap \
		-o lib/locale/ja.pot \
		./bin/kusanagi-docker \
		./lib/*.sh
msgmerge --no-wrap -U ./lib/locale/kusanagi-docker.po ./lib/locale/ja.pot
