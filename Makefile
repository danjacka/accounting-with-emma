.PHONY: run upload

run: ; tic80 -code-watch emma.fnl

# run "export html" in TIC80's shell to create emma.fnl.zip
upload: emma.fnl.zip
	butler push $< danjacka/accounting-with-emma:emma.zip
