.PHONY: default format lint gen_vimdoc gen_readme docs tests tests_selected tests_recent

.SILENT:
default: format lint tests docs

format:
	stylua --glob '*.lua' .

lint:
	selene --config selene/config.toml lua tests

gen_vimdoc:
	nvim --headless --noplugin -l bin/gen_vimdoc.lua

gen_readme:
	nvim --headless --noplugin -l bin/gen_readme.lua

docs: gen_vimdoc gen_readme

tests:
	@mkdir -p tmp
	@: > tmp/tests_state
	nvim --headless --noplugin -l bin/run_tests.lua

tests_selected:
	selected=$$(nvim --headless --noplugin -l bin/run_tests.lua --list 2>&1 | fzf --multi); \
	if [ -n "$$selected" ]; then \
		printf '%s' "$$selected" > tmp/tests_state; \
		FYLER_NVIM_TEST_SELECTED="$$selected" nvim --headless --noplugin -l bin/run_tests.lua; \
	fi

tests_recent:
	if [ -f tmp/tests_state ]; then \
		filter=$$(cat tmp/tests_state); \
		if [ -z "$$filter" ]; then \
			nvim --headless --noplugin -l bin/run_tests.lua; \
		else \
			FYLER_NVIM_TEST_SELECTED="$$filter" nvim --headless --noplugin -l bin/run_tests.lua; \
		fi \
	fi
