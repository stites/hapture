##
# haskell.nix helpers
#
# @file
# @version 0.1

package = hapture

lib:
	nix-build -A $(package).components.library

exe:
	nix-build -A $(package).components.exes.$(package)

release:
	nix-build ./release.nix

development:
	nix-build ./nix/development.nix

package-js: clean-js
	cd extension && zip -r hapture.zip *

clean-js:
	rm -rf extension/hapture.zip

install-server: exe
	cp -f ./result/bin/hapture ~/.local/bin/hapture
# end
