##
# Hapture
#
# @file
# @version 0.0.0

package: clean
	cd extension && zip -r hapture.zip *

clean:
	rm -rf extension/hapture.zip

# end
