preview :
	@echo "Serving the preview site ..."
	hugo serve --buildDrafts --buildFuture --disableFastRender --port=54321

build : 
	@echo "\nBuilding the website ..."
	hugo --cleanDestinationDir --minify
	@echo "Website finished building."

deploy : build
	@echo "\nDeploying the website ..."
	rsync --delete --omit-dir-times \
	  --exclude '.DS_Store' \
	  --exclude '.well-known' \
	  --exclude 'cgi-bin/' \
		--checksum -avz \
		--itemize-changes \
		public/ reclaim:~/legalmodernism.org/ | egrep -v '^\.'
