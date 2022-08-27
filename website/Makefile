preview :
	@echo "Serving the preview site ..."
	hugo serve --buildDrafts --buildFuture --disableFastRender --port=52643

build : 
	@echo "\nBuilding the website ..."
	hugo --cleanDestinationDir --minify
	@echo "Website finished building."

deploy : build
	@echo "\nDeploying the website ..."
	rsync --omit-dir-times \
	  --exclude '.htaccess' \
	  --exclude '.DS_Store' \
		--checksum -avz \
		--itemize-changes \
		public/ reclaim:~/legalmodernism.org/ | egrep -v '^\.'
